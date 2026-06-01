import * as cdk from 'aws-cdk-lib';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as path from 'path';
import { Construct } from 'constructs';

export class BackendStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // DynamoDB Tables
    const gastosTable = new dynamodb.Table(this, 'GastosTable', {
      tableName: 'gastos',
      partitionKey: { name: 'gastoId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    gastosTable.addGlobalSecondaryIndex({
      indexName: 'MesIndex',
      partitionKey: { name: 'yearMonth', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'timestamp', type: dynamodb.AttributeType.STRING },
    });

    const categoriasTable = new dynamodb.Table(this, 'CategoriasTable', {
      tableName: 'categorias',
      partitionKey: { name: 'categoriaId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    const participantesTable = new dynamodb.Table(this, 'ParticipantesTable', {
      tableName: 'participantes',
      partitionKey: { name: 'participanteId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // Common env vars for all Lambda functions
    const commonEnv: Record<string, string> = {
      GASTOS_TABLE: gastosTable.tableName,
      CATEGORIAS_TABLE: categoriasTable.tableName,
      PARTICIPANTES_TABLE: participantesTable.tableName,
      REGION: this.region,
    };

    // Helper to create a Go Lambda function
    const makeGoFn = (id: string, handlerPath: string): lambda.Function => {
      return new lambda.Function(this, id, {
        functionName: `gastos-${handlerPath.replace('/', '-')}`,
        runtime: lambda.Runtime.PROVIDED_AL2023,
        architecture: lambda.Architecture.ARM_64,
        handler: 'bootstrap',
        code: lambda.Code.fromAsset(path.join(__dirname, '../../functions'), {
          bundling: {
            image: lambda.Runtime.PROVIDED_AL2023.bundlingImage,
            environment: {
              GOCACHE: '/tmp/go-build',
              GOPATH: '/tmp/go',
            },
            command: [
              'bash',
              '-c',
              [
                'cd /asset-input',
                `GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -mod=vendor -tags lambda.norpc -o /asset-output/bootstrap ./${handlerPath}/`,
              ].join(' && '),
            ],
          },
        }),
        environment: commonEnv,
        timeout: cdk.Duration.seconds(10),
        memorySize: 128,
      });
    };

    // Lambda functions
    const fnCategList    = makeGoFn('CategoriasListFn',    'categorias/list');
    const fnCategCreate  = makeGoFn('CategoriasCreateFn',  'categorias/create');
    const fnPartList     = makeGoFn('ParticipantesListFn', 'participantes/list');
    const fnPartUpdate   = makeGoFn('ParticipantesUpdateFn', 'participantes/update');
    const fnGastosList   = makeGoFn('GastosListFn',        'gastos/list');
    const fnGastosCreate = makeGoFn('GastosCreateFn',      'gastos/create');
    const fnResumen      = makeGoFn('ResumenFn',            'resumen/get');

    // DynamoDB permissions
    categoriasTable.grantReadData(fnCategList);
    categoriasTable.grantReadWriteData(fnCategCreate);
    participantesTable.grantReadData(fnPartList);
    participantesTable.grantReadWriteData(fnPartUpdate);
    gastosTable.grantReadData(fnGastosList);
    gastosTable.grantReadWriteData(fnGastosCreate);
    gastosTable.grantReadData(fnResumen);
    categoriasTable.grantReadData(fnResumen);
    participantesTable.grantReadData(fnResumen);

    // API Gateway REST API with CORS
    const api = new apigateway.RestApi(this, 'GastosApi', {
      restApiName: 'GastosPersonalesApi',
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
        allowHeaders: ['Content-Type', 'Authorization'],
      },
    });

    // /categorias
    const categorias = api.root.addResource('categorias');
    categorias.addMethod('GET',  new apigateway.LambdaIntegration(fnCategList));
    categorias.addMethod('POST', new apigateway.LambdaIntegration(fnCategCreate));

    // /participantes + /participantes/{id}
    const participantes = api.root.addResource('participantes');
    participantes.addMethod('GET', new apigateway.LambdaIntegration(fnPartList));
    const participante = participantes.addResource('{id}');
    participante.addMethod('PUT', new apigateway.LambdaIntegration(fnPartUpdate));

    // /gastos
    const gastos = api.root.addResource('gastos');
    gastos.addMethod('GET',  new apigateway.LambdaIntegration(fnGastosList));
    gastos.addMethod('POST', new apigateway.LambdaIntegration(fnGastosCreate));

    // /resumen
    const resumen = api.root.addResource('resumen');
    resumen.addMethod('GET', new apigateway.LambdaIntegration(fnResumen));

    new cdk.CfnOutput(this, 'ApiUrl', {
      value: api.url,
      description: 'API Gateway URL — update ApiClient.baseUrl in the Flutter app',
    });
  }
}
