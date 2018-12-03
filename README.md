# AKS-Draft-DotNet
How to configure Dockerfile and VS Code to remotely debug with DRAFT an application that runs in a AKS cluster

## Environment pre-requirements
1. VS Code
2. Docker (not required, you can debug directly in AKS)
3. kubectl
4. az-cli
5. helm
6. draft
7. AKS cluster deployed on Azure
8. ACR to store container images on Azure

## Application preparation
1. <code>dotnet new web -n <app_name> -o .</code>
2. (optional) local debug in VS Code
  a. F5, when you hit it the first time it asks for creating a configuration
	b. Add Configuration... --> <code>.NET: Launch a local .NET Core Web Application</code>
  c. Add Configuration... --> <code>.NET: Attach to local .NET Core... </code>
	d. Run the application and the debugger

## Using DRAFT with Azure Kubernetes Service and Azure Container Registry
### Prepare the cluster to use DRAFT and HELM
1. Azure Login: <code>az login</code>
2. Get the credential for interact with the AKS cluster via kubectl from you development machine <code>az aks get-credentials -n cluster_name -g resource_group_name</code>
3. (**only if there is RBAC enabled on the AKS cluster**) <code>kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default</code>
4. Initialize helm client on your machine and the tiller on the cluster in Azure <code>helm init</code>
5. Initialize Draft for working with your application <code>draft init</code>

### Use DRAFT
1. Create the charts <code>draft create -p csharp</code> 
2. Configure draft to use ACR <code>draft config set registry ACR_name.azurecr.io</code>
3. ACR login <code>docker login ACR_name.azurecr.io</code>
4. (**only if you are using your custom Dockerfile, the Dockerfile that you can find in this solution is ready for the remote debug**) Changes required for the Dockerfile
    - change the configuration from <code>Release</code> to <code>Debug</code>
    - add the following code
    ```
      # install ps
      RUN apt-get update && apt-get install -y procps
      # Installing vsdbg debbuger into our container
      WORKDIR /vsdbg
      RUN apt-get update \
          && apt-get install -y --no-install-recommends \
          unzip \
          && rm -rf /var/lib/apt/lists/* \
          && curl -sSL https://aka.ms/getvsdbgsh | bash /dev/stdin -v latest -l ~/vsdbg
      ENV ASPNETCORE_ENVIRONMENT Development
      ENV DOTNET_RUNNING_IN_CONTAINER=true
      ENV DOTNET_USE_POLLING_FILE_WATCHER=true
    ```
5. Run the application in the cluster <code>draft up</code>
6. Get the pod name on which the application is running with the draft up command <code>kubectl get pods</code>
7. Change the launch.json file in the .vscode folder adding a new configuration as follow
  ```
  {
      "name": ".NET Core Attach (AKS)",
      "type": "coreclr",
      "request": "attach",
      "processId": "${command:pickRemoteProcess}",
      "justMyCode": true,
      "pipeTransport": {
          "pipeCwd": "${workspaceFolder}",
          "pipeProgram": "kubectl",
          "pipeArgs": ["exec", "-i", "dotnettest-dotnettest-8b87cf557-ssdbx", "--"],
          "debuggerPath": "/root/vsdbg/vsdbg",
          "quoteArgs": false
      },
      "sourceFileMap": {
          "/app": "${workspaceFolder}",
      "/src": "${workspaceFolder}"
      }
  }
  ```
8. Connect to the application in the cluster <code>draft connect</code>
9. Add a breakpoint and start debugging
