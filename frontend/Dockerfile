# I NEED TO RETEST THIS FOR NEW PROJECT
# Should be built by Azure Container Registry Task and uploaded to ACR by terraform
# Import latest python3 docker image
FROM python:3.8-slim-bullseye

# Install git
RUN apt-get -y update
RUN apt-get -y install git

# Clone github repository
RUN git clone https://github.com/blastomussa/AzureProjectF22.git /AzureProject/
WORKDIR /AzureProject/frontend

RUN pip3 install --no-cache-dir -r requirements.txt

# Expose the required port
EXPOSE 5000

# Must forward port when running container
CMD [ "python3", "./app.py" ]
