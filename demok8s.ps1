$SSHPublicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAiXeIV4vHyC4ZWBZh8WQDrovmA8SQjTWhSs6qwDG+AYctEJg0DHYbCArtMaYMSMEbHPZmd3E3ZsHMjO+eHYGV0CfghkaoPdmtCJEln8LkpyLKzFWL9G3z0dPoCdcCKsMpQDn18uHsr4enfQ2adfZ2D7h8Z4XI0LMZ7mGpoJ3vEZeq5fjGoTYmR3MC7y/NRFigXUbJjAs5+MiWpD6/BOzTFsycpGgVvwMS7/3BLBHCxBkYh3xR4wp7ZPzLyFRWgbiNGOGiFIzNu5zRG0mI6Aj5G9A6vWlA9OjZky9IVKPLg3YGci3DlP0IH40LY7FQuActE3HPiXHX2kassVLSsJkTLw== rsa-key-20161108"
$DNSPrefix = "k8s001RG"
$Password = "P4ssw0rd!"
 
# Connect to your Azure tenant
Add-AzureRmAccount
 
# We don't care avout URLs here :)
# Create the application
$app = New-AzureRmADApplication -DisplayName $DNSPrefix -HomePage "https://www.contoso.org/example" -IdentifierUris "https://www.contoso.org/k8s" -Password $Password
 
# Create the Sevice Principal
New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId
 
# Assign correct right for the SPN 
New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $app.ApplicationId.Guid
 
 # Generate the k8s template file
# Source: https://github.com/Azure/acs-engine/blob/master/examples/kubernetes.json
$k8sTemplate = @"
{
  "apiVersion": "vlabs",
  "properties": {
    "orchestratorProfile": {
      "orchestratorType": "Kubernetes"
    },
    "masterProfile": {
      "count": 1,
      "dnsPrefix": "$DNSPrefix",
      "vmSize": "Standard_D2_v2"
    },
    "agentPoolProfiles": [
      {
        "name": "agentpool1",
        "count": 3,
        "vmSize": "Standard_D2_v2",
        "availabilityProfile": "AvailabilitySet"
      }
    ],
    "linuxProfile": {
      "adminUsername": "azureuser",
      "ssh": {
        "publicKeys": [
          {
            "keyData": "$SSHPublicKey"
          }
        ]
      }
    },
    "servicePrincipalProfile": {
      "servicePrincipalClientID": "$($app.ApplicationId.Guid)",
      "servicePrincipalClientSecret": "$Password"
    }
  }
}
"@
 
$k8sTemplate | Out-File C:\GoWorkspace\Kubernetes.json -Encoding ANSI

Push-Location C:\GoWorkspace\src\github.com\Azure\acs-engine
.\acs-engine.exe C:\GoWorkspace\Kubernetes.json

Select-AzureRmSubscription -SubscriptionID 35034310-d309-4bff-8c85-86b74b709ca6
 
New-AzureRmResourceGroup -Name "k8sDemoMSCS007" -Location "West US"

# Changer le output directory ;)
New-AzureRmResourceGroupDeployment -Name "k8sDemoMSCS007" -ResourceGroupName "k8sDemoMSCS007" -TemplateFile _output\Kubernetes-33948742\azuredeploy.json -TemplateParameterFile _output\Kubernetes-33948742\azuredeploy.parameters.json