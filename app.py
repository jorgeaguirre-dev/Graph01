import os
import datetime
import graphene
from fastapi import FastAPI, Request
#from starlette.graphql import GraphQLApp
from ariadne.asgi import GraphQL # sólo el servidor para el esquema de Graphene
from mangum import Mangum
import boto3
from botocore.exceptions import ClientError

# --- ESQUEMA GRAPHENE ---
class Item(graphene.ObjectType):
    id = graphene.ID()
    name = graphene.String()
    created_at = graphene.String()

class Query(graphene.ObjectType):
    get_item = graphene.Field(Item, id=graphene.ID(required=True))

    def resolve_get_item(root, info, id):
        # MOCK PARA LINUX
        if os.environ.get("AWS_EXECUTION_ENV") is None:
            return {"id": id, "name": "Item Local", "created_at": "2024-01-01"}
        
        # LÓGICA AWS (Se activa en Lambda)
        import boto3
        table = boto3.resource('dynamodb').Table(os.environ['TABLE_NAME'])
        res = table.get_item(Key={'id': id})
        return res.get('Item')

# --- MUTATION ---
class CreateItem(graphene.Mutation):
    class Arguments:
        id = graphene.ID(required=True)
        name = graphene.String(required=True)

    # Lo que devuelve la mutación
    ok = graphene.Boolean()
    item = graphene.Field(lambda: Item)

    def mutate(root, info, id, name):
        timestamp = datetime.datetime.now().isoformat()
        new_item = {
            "id": id, 
            "name": name, 
            "created_at": timestamp
        }

        # Lógica de persistencia
        if os.environ.get("AWS_EXECUTION_ENV"):
            # MODO AWS
            table_name = os.environ.get("TABLE_NAME", "MiTablaGraphene")
            dynamodb = boto3.resource('dynamodb')
            table = dynamodb.Table(table_name)
            table.put_item(Item=new_item)
        else:
            # MODO LOCAL (Simulacro)
            print(f"DEBUG: Guardando en Local/Mock: {new_item}")

        return CreateItem(ok=True, item=new_item)

class Mutation(graphene.ObjectType):
    create_item = CreateItem.Field()

schema = graphene.Schema(query=Query, mutation=Mutation)

# --- APP FASTAPI ---
app = FastAPI()
graphql_app = GraphQL(schema.graphql_schema, debug=True)

# api_route permite especificar múltiples métodos
@app.api_route("/graphql", methods=["GET", "POST"])
async def graphql_route(request: Request):
    return await graphql_app.handle_request(request)

# Redirección opcional de la raíz al explorador
@app.api_route("/", methods=["GET", "POST"])
async def root(request: Request):
    return await graphql_app.handle_request(request)

# Adaptador para AWS Lambda
handler = Mangum(app)