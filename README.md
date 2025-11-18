## Prueba tecnica

Resumen: Este proyecto despliega 2 clusters de kubernetes utilizando kind y terraform como iac

- Cluster de deployment:
  Jenkins
  Vault

- Cluster de development:
  Microservice de java 17 con spring boot, tipo loadbalancer con 2 replicas

Se lee el secreto desde vault, se inyecta como variable de entorno desde el pipeline de jenkins, se construye y sube la imagen de Docker al registry y se despliega el microservice, exponiendo dos endpoints:

GET /secret - Secreto leido desde vault
GET /config - Variable de configuracion local


## Prerrequisitos

Docker
kind
kubectl
git o Github Desktop
terraform
Java 17 y Maven
Acceso a Docker Hub (Actualmente configurado con la ruta docker.io/davidmauricio/microservice)

## Clonar repositorio de github y ejecutar terraform

1. `git clone https://github.com/davidmauricio/prueba-tecnica-cusca.git`
2. `cd /iac/terraform`
3. `terraform init`
4. `terraform apply`

Digitar `yes` cuando terraform pregunte. Tambien se puede ejecutar  `terraform apply -auto-approve` para evitar digitar  `yes`

5. Verificar cluster creados `kubectl config get-contexts` 

## Verificar y configuar jenkins

1. Verificar la creacion de jenkins
`kubectl config use-context kind-deployment-cluster` para seleccionar cluster de deployement
`kubectl get pods -n ci -w` ver el pod de jenkins con el namespace ci, debe estar en estado "Runing"

Ejecutar `kubectl config view --minify --flatten --context kind-dev-cluster > dev-kubeconfig` para crear el secret de jenkins que se usa para ejecutar kubectl.
Esto crea el archivo y modificamos la ruta del server por  `https://host.docker.internal` y el puerto que nos pone, solo se edita la url
Luego ejecutamos  `kubectl --context kind-deployment-cluster -n ci create secret generic dev-kubeconfig --from-file=kubeconfig=dev-kubeconfig` para crear el secret en el cluster de deployment

`kubectl port-forward svc/jenkins -n ci 8081:8080` para levantar el jenkins y desde el navegador ir a  `http://localhost:8081/`

2. Instalar plugins necesarios desde la "Administrar jenkins" (pipeline, git, kubernetes)

3. Agregar credenciales necesarias, Administrar jenkins y luego en credentials, agregar 

-Vault
  tipo: `Secret Text` 
  ID: `vault-token`
  Secret: `root`

-Doker Hub
  tipo: `Username y password`
  ID:  `dockerhub-creds`
  Usario y password segun credenciaels de Docker Hub

4. Agregar cloud de kubernetes
  Ir a adminsitrar jenkins, luego a Clouds, agregar una nueva, cloud name le ponemos `kubernetes` y en tipo seleccionamos Kubernetes
  En jenkins url ponemos  `http://jenkins.ci.svc.cluster.local:8080`, damos en guardar

## Crear pipeline en jenkins

1. Crear un job tipo pipeline con el nombre `microservice-pipeline`
2. Configurar Pipeline from SCM, SCM tipo git, usar url de repositorio, en este caso se uso `https://github.com/davidmauricio/prueba-tecnica-cusca.git`, en branch digitamos  `main` y la ruta de jenkins es `jenkins/Jenkinsfile`
3. Guardar y ejecutar job desde Construir ahora

## Verificar deployment

1. digitamos `kubectl --context kind-dev-cluster -n development get pods` para ver los pods de development, deberian estar 2 en estado running 
2. verificamos el loadbalancer  `kubectl --context kind-dev-cluster -n development get svc microservice-lb` se deberia ver el microservice de tipo load balancer
3. Desde el navegador verificamos los endpoints

 `http://localhost:8080/secret` y  `http://localhost:8080/config`

## Verificar secreto desde vault

1. Levantamos el vault con namespace de este nombre `kubectl --context kind-deployment-cluster -n vault port-forward svc/vault 8200:8200`
2. Desde otra terminal podemos hacer un CURL  `curl -H "X-Vault-Token: root"  http://127.0.0.1:8200/v1/secret/data/microservice`, deberia mostrar el secret desde vault





