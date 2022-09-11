# Import latest python3 docker image
FROM python:3.8-slim-bullseye

# Install git
RUN apt-get -y update
RUN apt-get -y install git

# Clone github repository
RUN git clone https://github.com/blastomussa/Azure-NTier-Terraform.git /AzureProject/
WORKDIR /AzureProject/frontend

RUN pip3 install --no-cache-dir -r requirements.txt

# Expose the required port
EXPOSE 80

CMD [ "python3", "./app.py" ]
