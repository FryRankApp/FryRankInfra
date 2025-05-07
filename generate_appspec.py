import json
import os
import boto3
import yaml

def generate_appspec():
    lambda_client = boto3.client('lambda')
    lambda_functions = json.loads(os.environ.get('LAMBDA_FUNCTIONS', '{}'))
    
    # Create resources list for all functions
    resources = []
    for key, function in lambda_functions.items():
        function_name = function['name']
        
        # Get current function version
        function_info = lambda_client.get_function(FunctionName=function_name)
        current_version = function_info['Configuration']['Version']
        
        # Create new version
        new_version = lambda_client.publish_version(
            FunctionName=function_name
        )['Version']
        
        # Add function to resources
        resources.append({
            function_name: {
                'Type': 'AWS::Lambda::Function',
                'Properties': {
                    'Name': function_name,
                    'Alias': 'Production',
                    'CurrentVersion': current_version,
                    'TargetVersion': new_version
                }
            }
        })
    
    # Create single appspec with all functions
    appspec = {
        'version': '0.0',
        'Resources': resources
    }
    
    # Write appspec file
    with open('appspec.yml', 'w') as f:
        f.write(yaml.dump(appspec, default_flow_style=False))

def main():
    generate_appspec()

if __name__ == '__main__':
    main()
