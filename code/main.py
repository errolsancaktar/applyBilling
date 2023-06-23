import base64
import os
import json
import functions_framework
import logging
from google.cloud import billing_v1


## Apply Environment Variables ##
billingAccount = os.environ['LP_BILLING_ACCOUNT']

## Set Loglevel ##
logging.setLevel("info")
# Triggered from a message on a Cloud Pub/Sub topic.


@functions_framework.cloud_event
def hello_pubsub(cloud_event):
    # Print out the data from Pub/Sub, to prove that it worked
    logData = json.loads(base64.b64decode(cloud_event.data["message"]["data"]))
    logging.debug("Log Output:")
    logging.debug(logData)
    logging.info("Project ID:")
    projectID = logData['protoPayload']['request']['project']['projectId']
    logging.info(projectID)
    creation_user = logData['protoPayload']['authenticationInfo']['principalEmail']
    logging.info("Creator:")
    logging.info(creation_user)
    fullProj = "projects/" + projectID
    if (isBillingEnabled(fullProj)):
        applyBilling(projectID, billingAccount)


def isBillingEnabled(project, billingAccount):

    billingClient = billing_v1.CloudBillingClient()
    request = billing_v1.GetProjectBillingInfoRequest(
        name=project,
    )
    response = billingClient.get_project_billing_info(request=request)
    logging.debug(response)
    return response


def applyBilling(project):

    billingClient = billing_v1.CloudBillingClient()
    request = billing_v1.UpdateBillingAccountRequest(
        name=project,
    )
    response = billingClient.update_billing_account(request=request)
    logging.debug(response)

    return response
