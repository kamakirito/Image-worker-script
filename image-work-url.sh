#!/bin/bash

# Remove specific docker-related packages if they are installed
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
    sudo apt-get remove $pkg -y
done

# Update the package lists for upgrades and new package installations
sudo apt-get update -y

# Install necessary packages for fetching files over HTTPS
sudo apt-get install ca-certificates curl -y

# Create a directory for apt keyrings and set permissions
sudo install -m 0755 -d /etc/apt/keyrings

# Download Docker's official GPG key and save it to the keyrings directory
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

# Set read permissions for the Docker GPG key for all users
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker's APT repository to the sources list of apt package manager
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the apt package list after adding new repository
sudo apt-get update -y

# Install Docker Engine, CLI, containerd, and Docker compose plugins
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Test Docker installation by running the hello-world container
docker run hello-world

echo "Pulling the docker image"

docker pull corcelio/vision:image_server-latest

echo "Installing Conda"
export PYTHON_VERSION=3.10.13
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod 700 Miniconda3-latest-Linux-x86_64.sh
./Miniconda3-latest-Linux-x86_64.sh -b -u

# Setup Conda environment
echo 'source "$HOME/miniconda3/etc/profile.d/conda.sh"' >> ~/.bashrc && \
echo 'if [ -f ~/.bashrc ]; then . ~/.bashrc; fi' >> ~/.bash_profile && \
echo 'source "$HOME/miniconda3/etc/profile.d/conda.sh"' >> ~/.profile && \
source ~/.bashrc

conda create -n venv python=$PYTHON_VERSION -y
conda activate venv

echo "conda activate venv" >> ~/.bashrc

sudo apt install nvidia-cuda-toolkit  # (You might need to restart services when prompted)

# Now install nvidia runtime
CUDA_VERSION="11.8.0"
conda install nvidia/label/cuda-$CUDA_VERSION::cuda-toolkit -y

distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update
sudo apt-get install nvidia-docker2

which nvidia-container-runtime

sudo systemctl restart docker

# # Check for NVCC version 11.8
# version_output=$(nvcc --version 2>&1)
# running_image_worker_message =
# if [[ $version_output == *"11.8"* ]]; then
#     echo -e "\e[32m$version_output\e[0m"
#     echo -e "\e[32m$version_output\e[0m"
# else
#     echo -e "\e[31mExpected NVCC version 11.8 not found.\e[0m"
# fi

# Check for NVCC version 11.8
version_output=$(nvcc --version 2>&1)
if [[ $version_output == *"11.8"* ]]; then
    echo -e "\e[32m$version_output\e[0m"
    
    # Prompt for port number
    read -p "Enter the port number: " port_number
    # Prompt for device ID
    read -p "Enter the device ID: " device_id
    
    echo "Review Port number: $port_number, Device ID: $device_id" # Optionally display the input for confirmation
    
    # Pulling Docker image

    while true; do
        read -p "Do you wish to proceed with the Docker command? (y/n): " yn
        case $yn in
            [Yy]* ) 
                # Pulling Docker image
                docker pull corcelio/vision:image_server-latest

                # Running Docker container with dynamic port and device ID
                docker run --gpus '"device=device_id"' --runtime=nvidia -p $port_number:$port_number -e PORT=port_number -e DEVICE=0 -e --WARMUP=true -e --gpu-only corcelio/vision:image_server-latest
                break;;
            [Nn]* ) 
                echo "Docker command execution aborted."
                break;;
            * ) 
                echo "Please answer yes (y) or no (n).";;
        esac
    done
    
else
    echo -e "\e[31mExpected NVCC version 11.8 not found.\e[0m"
fi

