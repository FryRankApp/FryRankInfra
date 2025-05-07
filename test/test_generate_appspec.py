import os
import json
import yaml
import hcl2
import sys
from unittest.mock import patch, MagicMock

# Add parent directory to Python path to import generate_appspec
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from generate_appspec import generate_appspec

def load_lambda_functions():
    print("Loading lambda.tf file...")
    # Get the project root directory
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    lambda_tf_path = os.path.join(project_root, 'stack', 'lambda.tf')
    
    with open(lambda_tf_path, 'r') as f:
        tf_config = hcl2.load(f)
        print(f"Parsed HCL config: {json.dumps(tf_config, indent=2)}")
        # Extract lambda_functions from locals block
        if 'locals' in tf_config:
            locals_blocks = tf_config['locals']
            if isinstance(locals_blocks, list) and len(locals_blocks) > 0:
                locals_block = locals_blocks[0]  # Get the first locals block
                if 'lambda_functions' in locals_block:
                    functions = locals_block['lambda_functions']
                    print(f"Found lambda functions: {json.dumps(functions, indent=2)}")
                    return functions
    print("No lambda functions found in config!")
    return {}

def validate_appspec():
    print("\nValidating appspec.yml...")
    # Mock AWS Lambda client
    mock_lambda = MagicMock()
    mock_lambda.get_function.return_value = {
        'Configuration': {'Version': '1'}
    }
    mock_lambda.publish_version.return_value = {'Version': '2'}
    
    # Generate the appspec file with mocked AWS client
    with patch('boto3.client', return_value=mock_lambda):
        print("Generating appspec.yml...")
        generate_appspec()
    
    # Verify the file was created
    assert os.path.exists('appspec.yml'), "AppSpec file appspec.yml was not created"
    
    # Read and parse the generated file
    with open('appspec.yml', 'r') as f:
        generated = yaml.safe_load(f)
    
    # Validate structure
    assert generated['version'] == '0.0', "Version should be 0.0"
    assert 'Resources' in generated, "Should have Resources section"
    
    # Get all function names from lambda.tf
    lambda_functions = load_lambda_functions()
    expected_function_count = len(lambda_functions)
    assert len(generated['Resources']) == expected_function_count, f"Should have exactly {expected_function_count} resources"
    
    # Validate each function
    for key, function in lambda_functions.items():
        function_name = function['name']
        # Find the resource for this function
        function_resource = None
        for resource in generated['Resources']:
            if function_name in resource:
                function_resource = resource[function_name]
                break
        
        assert function_resource is not None, f"Resource for {function_name} not found"
        assert function_resource['Type'] == 'AWS::Lambda::Function', f"Type should be AWS::Lambda::Function for {function_name}"
        
        properties = function_resource['Properties']
        required_props = ['Name', 'Alias', 'CurrentVersion', 'TargetVersion']
        for prop in required_props:
            assert prop in properties, f"Properties should include {prop} for {function_name}"
        
        assert properties['Name'] == function_name, f"Name should match function name for {function_name}"
        assert properties['Alias'] == 'Production', f"Alias should be Production for {function_name}"
        assert properties['CurrentVersion'] == '1', f"CurrentVersion should be 1 for {function_name}"
        assert properties['TargetVersion'] == '2', f"TargetVersion should be 2 for {function_name}"
    
    print("[PASS] Validation passed for all functions")
    print("Generated AppSpec:")
    print(yaml.dump(generated, default_flow_style=False))
    print("---")

def main():
    # Load Lambda functions from lambda.tf
    lambda_functions = load_lambda_functions()
    os.environ['LAMBDA_FUNCTIONS'] = json.dumps(lambda_functions)
    
    # Generate and validate appspec
    validate_appspec()

if __name__ == '__main__':
    main()
