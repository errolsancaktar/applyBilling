import base64
import functions_framework
import json
from google.cloud import billing_v1




# Triggered from a message on a Cloud Pub/Sub topic.
@functions_framework.cloud_event
def hello_pubsub(cloud_event):
    # Print out the data from Pub/Sub, to prove that it worked
    logData = json.loads(base64.b64decode(cloud_event.data["message"]["data"]))
    print("Log Output:")
    print(logData)
    print("Project ID:")
    projectID = logData['protoPayload']['request']['project']['projectId']
    print(projectID)
    creation_user = logData['protoPayload']['authenticationInfo']['principalEmail']
    print("Creator:")
    print(creation_user)
    fullProj = "projects/" + projectID
    print(_is_billing_enabled(fullProj))

def _is_billing_enabled(project):

    billingClient = billing_v1.CloudBillingClient()
    request = billing_v1.GetProjectBillingInfoRequest(
        name=project,
    )
    response = billingClient.get_project_billing_info(request=request)

    return response


