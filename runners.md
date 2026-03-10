# Azure

    Para fazer download do azure 
        curl -o vsts-agent-osx-arm64.tar.gz -L https://download.agent.dev.azure.com/agent/5.270.0/vsts-agent-osx-arm64-5.270.0.tar.gz
    Para dar unzip
        tar zxvf vsts-agent-osx-arm64.tar.gz
    Para permitir executar o runner dentro da pasta:
        xattr -r -d com.apple.quarantine "/Users/fredericoprazeres/Tese/runners/azure"
    Para o configurar
        ./config.sh
        Server: https://dev.azure.com/fc56269/
        Personal Access Token
        Tese Mestrado Pool
        ./run.sh
    