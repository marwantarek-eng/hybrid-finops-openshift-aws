import os
import boto3

rds = boto3.client('rds')

def lambda_handler(event, context):
    db_instance_id = os.environ.get('DB_INSTANCE_IDENTIFIER')
    action = event.get('action', '').lower()

    if not db_instance_id:
        return {"status": "error", "message": "DB_INSTANCE_IDENTIFIER env var missing"}

    # 1. فحص حالة قاعدة البيانات الحالية والـ Tags
    response = rds.describe_db_instances(DBInstanceIdentifier=db_instance_id)
    db_instance = response['DBInstances'][0]
    current_status = db_instance['DBInstanceStatus']
    arn = db_instance['DBInstanceArn']

    # 2. فحص استثناء ضغط الشغل (Override)
    tags_response = rds.list_tags_for_resource(ResourceName=arn)
    tag_list = {t['Key']: t['Value'] for t in tags_response.get('TagList', [])}
    
    if tag_list.get('AutoStop', '').lower() == 'false' and action == 'stop':
        print(f"Skipping stop for {db_instance_id}: AutoStop tag is set to false.")
        return {"status": "skipped", "reason": "AutoStop tag disabled"}

    # 3. إيقاف السيرفر
    if action == 'stop':
        if current_status == 'available':
            print(f"Stopping RDS instance: {db_instance_id}")
            rds.stop_db_instance(DBInstanceIdentifier=db_instance_id)
            return {"status": "success", "message": f"DB {db_instance_id} stopping"}
        else:
            return {"status": "ignored", "current_status": current_status}

    # 4. تشغيل السيرفر
    elif action == 'start':
        if current_status == 'stopped':
            print(f"Starting RDS instance: {db_instance_id}")
            rds.start_db_instance(DBInstanceIdentifier=db_instance_id)
            return {"status": "success", "message": f"DB {db_instance_id} starting"}
        else:
            return {"status": "ignored", "current_status": current_status}

    return {"status": "error", "message": f"Invalid action: {action}"}