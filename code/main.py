import base64
import os
import json
import functions_framework
from google.cloud import billing_v1

billingAccount = os.environ['LP_BILLING_ACCOUNT']


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
    if (isBillingEnabled(fullProj)):
        applyBilling(projectID, billingAccount)


def isBillingEnabled(project, billingAccount):

    billingClient = billing_v1.CloudBillingClient()
    request = billing_v1.GetProjectBillingInfoRequest(
        name=project,
    )
    response = billingClient.get_project_billing_info(request=request)

    return response


def applyBilling(project):

    billingClient = billing_v1.CloudBillingClient()
    request = billing_v1.UpdateBillingAccountRequest(
        name=project,
    )
    response = billingClient.update_billing_account(request=request)

    return response
