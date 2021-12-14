# Set the below variables
export UNIQUE_SUFFIX_CAPPS="<your-unique-suffix>"
export SUBSCRIPTION_ID="<your-subscription-id>"
export LOCATION_CAPPS="canadacentral"
export RESOURCE_GROUP_CAPPS="cappsdemo-$UNIQUE_SUFFIX_CAPPS"
export LOG_ANALYTICS_WORKSPACE_CAPPS="$RESOURCE_GROUP_CAPPS-logs"
export CONTAINERAPPS_ENVIRONMENT_CAPPS="$RESOURCE_GROUP_CAPPS-env"
export ACR_NAME_CAPPS="cappsdemoacr$UNIQUE_SUFFIX_CAPPS"
export ACR_LOGIN_CAPPS="$ACR_NAME_CAPPS.azurecr.io"
export ACR_USERNAME_CAPPS="$ACR_NAME_CAPPS"
export SB_NAME_CAPPS="cappsdemosb$UNIQUE_SUFFIX_CAPPS"
export STORAGE_ACCOUNT_CAPPS="cappsdemosa$UNIQUE_SUFFIX_CAPPS"
export BLOB_CONTAINER_CAPPS="orders$UNIQUE_SUFFIX_CAPPS"

# run the saveenv.sh script at any time to save environment variables created above to capps.env
# deploy/AzureContainerApps/bash/saveenv.sh
# run this command to access the saved environment variables 
# source capps.env

# Login to Azure and set appropriate subscription 
az login
az account set -s "$SUBSCRIPTION_ID"

# Upgrade Azure CLI and install Azure Container Apps extension
az upgrade 
az extension add --source https://workerappscliextension.blob.core.windows.net/azure-cli-extension/containerapp-0.2.1-py2.py3-none-any.whl
az provider register --namespace Microsoft.Web

# Create Azure Resource Group 
az group create --name $RESOURCE_GROUP_CAPPS --location $LOCATION_CAPPS

# Provision Azure Resources 

# Provision an Azure Container Registry and retrieve credentials 
az acr create --resource-group $RESOURCE_GROUP_CAPPS --name $ACR_NAME_CAPPS --sku Basic --admin-enabled true
export ACR_PASSWORD_CAPPS=$(az acr credential show -n $ACR_NAME_CAPPS --query "passwords[0].value" -o tsv)

# Provision an Azure Storage Account and a blob container and retrieve the credentials 
az storage account create \
    --name $STORAGE_ACCOUNT_CAPPS \
    --resource-group $RESOURCE_GROUP_CAPPS \
    --location $LOCATION_CAPPS \
    --sku Standard_LRS \
    --kind StorageV2

az storage container create --account-name $STORAGE_ACCOUNT_CAPPS --name $BLOB_CONTAINER_CAPPS

export STORAGE_ACCOUNT_KEY_CAPPS=$(az storage account keys list --resource-group $RESOURCE_GROUP_CAPPS --account-name $STORAGE_ACCOUNT_CAPPS --query '[0].value' --out tsv)

# Provision an Azure Service Bus Namespace and retrieve the root connection string 
az servicebus namespace create --resource-group $RESOURCE_GROUP_CAPPS --name $SB_NAME_CAPPS --location $LOCATION_CAPPS
export SB_CONNECTIONSTRING_CAPPS="$(az servicebus namespace authorization-rule keys list --resource-group $RESOURCE_GROUP_CAPPS --namespace-name $SB_NAME_CAPPS --name RootManageSharedAccessKey --query primaryConnectionString --output tsv)"

# Create Log Analytics Workspace 
az monitor log-analytics workspace create --resource-group $RESOURCE_GROUP_CAPPS --workspace-name $LOG_ANALYTICS_WORKSPACE_CAPPS
export LOG_ANALYTICS_WORKSPACE_CLIENT_ID_CAPPS=$(az monitor log-analytics workspace show --query customerId -g $RESOURCE_GROUP_CAPPS -n $LOG_ANALYTICS_WORKSPACE_CAPPS --out tsv)
export LOG_ANALYTICS_WORKSPACE_CLIENT_SECRET_CAPPS=$(az monitor log-analytics workspace get-shared-keys --query primarySharedKey -g $RESOURCE_GROUP_CAPPS -n $LOG_ANALYTICS_WORKSPACE_CAPPS --out tsv)

# Create Container Apps Environment
az containerapp env create \
  --name $CONTAINERAPPS_ENVIRONMENT_CAPPS \
  --resource-group $RESOURCE_GROUP_CAPPS \
  --logs-workspace-id $LOG_ANALYTICS_WORKSPACE_CLIENT_ID_CAPPS \
  --logs-workspace-key $LOG_ANALYTICS_WORKSPACE_CLIENT_SECRET_CAPPS \
  --location $LOCATION_CAPPS

# Use ACR Tasks to build and push your images to Azure Container Registry (run from root directory)
az acr build -t web -r $ACR_NAME_CAPPS -f Frontend/CloudChampion.Web/Dockerfile .
az acr build -t order -r $ACR_NAME_CAPPS -f Services/CloudChampion.Order/Dockerfile .

# Modify the components.yaml with the appropriate input 
cat deploy/AzureContainerApps/bash/components.yaml | \
    sed "s#<storage-account-name>#${STORAGE_ACCOUNT_CAPPS}#g" | \
    sed "s#<blob-container-name>#${BLOB_CONTAINER_CAPPS}#g" | \
    > deploy/AzureContainerApps/bash/mycomponents.yaml

# Deploy the container apps (run from root directory)
 az containerapp create \
  --name order \
  --resource-group $RESOURCE_GROUP_CAPPS \
  --environment $CONTAINERAPPS_ENVIRONMENT_CAPPS \
  --secrets "accountkey=$STORAGE_ACCOUNT_KEY_CAPPS,connectionstring=$SB_CONNECTIONSTRING_CAPPS" \
  --registry-login-server $ACR_LOGIN_CAPPS \
  --registry-username $ACR_NAME_CAPPS \
  --registry-password $ACR_PASSWORD_CAPPS \
  --image $ACR_LOGIN_CAPPS/order:latest \
  --min-replicas 1 \
  --max-replicas 1 \
  --enable-dapr \
  --dapr-app-port 80 \
  --dapr-app-id cloudchampion-order \
  --dapr-components deploy/AzureContainerApps/bash/mycomponents.yaml

az containerapp create \
  --name web \
  --resource-group $RESOURCE_GROUP_CAPPS \
  --environment $CONTAINERAPPS_ENVIRONMENT_CAPPS \
  --registry-login-server $ACR_LOGIN_CAPPS \
  --registry-username $ACR_USERNAME_CAPPS \
  --registry-password $ACR_PASSWORD_CAPPS \
  --secrets "accountkey=$STORAGE_ACCOUNT_KEY_CAPPS,connectionstring=$SB_CONNECTIONSTRING_CAPPS" \
  --image $ACR_LOGIN_CAPPS/web:latest \
  --target-port 80 \
  --ingress 'external' \
  --min-replicas 1 \
  --max-replicas 1 \
  --enable-dapr \
  --dapr-app-port 80 \
  --dapr-app-id cloudchampion-web \
  --dapr-components deploy/AzureContainerApps/bash/mycomponents.yaml


 