import boto3
import os

def lambda_handler(event, context):
    # Initialize S3 client
    s3 = boto3.client('s3')

    # Get bucket and key from the S3 event
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    source_key = event['Records'][0]['s3']['object']['key']

    # Get destination bucket from environment variable
    destination_bucket = os.environ['DESTINATION_BUCKET']

    try:
        # Read the file from the source bucket
        response = s3.get_object(Bucket=source_bucket, Key=source_key)
        file_content = response['Body'].read().decode('utf-8')

        # Process the file (in this case, convert to uppercase)
        processed_content = file_content.upper()

        # Write the processed content to the destination bucket
        destination_key = f"{source_key}-formatted"
        s3.put_object(Bucket=destination_bucket, Key=destination_key, Body=processed_content)

        print(f"File processed successfully: {source_bucket}/{source_key} -> {destination_bucket}/{destination_key}")
        return {
            'statusCode': 200,
            'body': f"File processed and uploaded to {destination_bucket}/{destination_key}"
        }

    except Exception as e:
        print(f"Error processing file {source_key} from bucket {source_bucket}: {str(e)}")
        return {
            'statusCode': 500,
            'body': f"Error processing file: {str(e)}"
        }