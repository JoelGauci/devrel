# Apigee Mock Target based on Open API Spec

A set of tooling and reference material for Apigee
to generate a mock target based on an OpenAPI Spec.

## API Facade on Google CLoud Run

It is very useful for API developers to work with mocks based on Open API
specs.
Many different NodeJS frameworks allow the creation of "smart" mock targets
based on Open API specs.
In this example, we have choosen to use [openapi-mock-express-middleware](https://www.npmjs.com/package/openapi-mock-express-middleware),
which is a NodeJS module that can generate an express mock server from an
Open API 3.0 documentation.

## Prerequisites

- Create a free Apigee account in order to use Apigee X or hybrid
- Install Git
- Install Maven
- A Google Cloud account (trial or paid)

## Quickstart Usage

For the best compatibility, run from a Google Cloud Shell

```sh
export APIGEE_X_HOSTNAME=xxx
export APIGEE_X_ORG=xxx
export APIGEE_X_ENV=xxx
export GCP_PROJECT=xxx

git clone -b feature/apigee-mock-target https://github.com/JoelGauci/devrel.git

cd ./devrel/tools/_apigee-mock-target
```

At this point you need to define the ```OPEN_API_SPEC_MOCK``` env. variable.
The ```OPEN_API_SPEC_MOCK``` refers to the relative path of the Open
API spec file you want to use to implement the mock target.
As an example, you can create a ```specs``` directory in the
current folder and put your Open API specs (let's try [petstore.yaml](https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/examples/v3.0/petstore.yaml))
into it. In that case the ```OPEN_API_SPEC_MOCK``` is defined using
the following command:

```sh
mkdir specs && cd ./specs

curl -L0 https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/examples/v3.0/petstore.yaml > petstore.yaml

cd ..

export OPEN_API_SPEC_MOCK=./specs/petstore.yaml
```

Before running the pipeline, please update your ```PATH``` in order
to add ```sackmesser``` to it (if you have not installed it yet!)

```sh
export PATH="$PATH":"../apigee-sackmesser/bin/"
```

Install xmllint

```sh
sudo apt install libxml2-utils
```

Now you can run the ```pipeline.sh``` script

```sh
./pipeline.sh
```

## Result

- NodeJS app (implementing a mock target based on an Open API Spec)
deployed to Cloud Run
- Apigee Proxy Configured with service account keys to connect to the Cloud Run app,
  Spike Arrest

## Extend

At this point you can create other Apigee target endpoints on your API proxy
and route to the Open API spec mock target under specific conditions
like the presence of an HTTP header ```x-mock``` with value ```true```
