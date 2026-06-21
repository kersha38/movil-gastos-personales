import * as cdk from 'aws-cdk-lib';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as events from 'aws-cdk-lib/aws-events';
import * as targets from 'aws-cdk-lib/aws-events-targets';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import * as path from 'path';
import { execSync } from 'child_process';
import { Construct } from 'constructs';

export class BackendStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // ─── DynamoDB Tables ────────────────────────────────────────────────────

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

    const transferenciasTable = new dynamodb.Table(this, 'TransferenciasTable', {
      tableName: 'transferencias',
      partitionKey: { name: 'transferenciaId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });
    transferenciasTable.addGlobalSecondaryIndex({
      indexName: 'MesIndex',
      partitionKey: { name: 'yearMonth', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'timestamp', type: dynamodb.AttributeType.STRING },
    });

    const gastosMensualesTable = new dynamodb.Table(this, 'GastosMensualesTable', {
      tableName: 'gastos-mensuales',
      partitionKey: { name: 'gastoMensualId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });
    // List all plantillas or instancias by tipo
    gastosMensualesTable.addGlobalSecondaryIndex({
      indexName: 'TipoIndex',
      partitionKey: { name: 'tipo', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'gastoMensualId', type: dynamodb.AttributeType.STRING },
    });
    // List all instancias of a plantilla
    gastosMensualesTable.addGlobalSecondaryIndex({
      indexName: 'TemplateIdIndex',
      partitionKey: { name: 'plantillaId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'yearMonth', type: dynamodb.AttributeType.STRING },
    });

    // ��── Common env vars ────────────────────────────────────────────────────

    const commonEnv: Record<string, string> = {
      GASTOS_TABLE: gastosTable.tableName,
      CATEGORIAS_TABLE: categoriasTable.tableName,
      PARTICIPANTES_TABLE: participantesTable.tableName,
      TRANSFERENCIAS_TABLE: transferenciasTable.tableName,
      GASTOS_MENSUALES_TABLE: gastosMensualesTable.tableName,
      REGION: this.region,
    };

    // ─── Lambda helper ──────────────────────────────────────────────────────

    const makeGoFn = (id: string, handlerPath: string): lambda.Function => {
      return new lambda.Function(this, id, {
        functionName: `gastos-${handlerPath.replace(/\//g, '-')}`,
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
              'bash', '-c',
              [
                'cd /asset-input',
                `GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -mod=vendor -tags lambda.norpc -o /asset-output/bootstrap ./${handlerPath}/`,
              ].join(' && '),
            ],
          },
        }),
        environment: commonEnv,
        timeout: cdk.Duration.seconds(30),
        memorySize: 128,
      });
    };

    // ─── Lambda functions ────────────────────────────────────────────────────

    const fnCategList        = makeGoFn('CategoriasListFn',       'categorias/list');
    const fnCategCreate      = makeGoFn('CategoriasCreateFn',     'categorias/create');
    const fnPartList         = makeGoFn('ParticipantesListFn',    'participantes/list');
    const fnPartUpdate       = makeGoFn('ParticipantesUpdateFn',  'participantes/update');
    const fnGastosList       = makeGoFn('GastosListFn',           'gastos/list');
    const fnGastosCreate     = makeGoFn('GastosCreateFn',         'gastos/create');
    const fnGastosUpdate     = makeGoFn('GastosUpdateFn',         'gastos/update');
    const fnGastosVerificar  = makeGoFn('GastosVerificarFn',      'gastos/verificar');
    const fnResumen          = makeGoFn('ResumenFn',               'resumen/get');
    const fnTrList           = makeGoFn('TransferenciasListFn',   'transferencias/list');
    const fnTrCreate         = makeGoFn('TransferenciasCreateFn', 'transferencias/create');
    const fnTrDelete         = makeGoFn('TransferenciasDeleteFn', 'transferencias/delete');
    const fnGmList           = makeGoFn('GastosMensualesListFn',  'gastos-mensuales/list');
    const fnGmCreate         = makeGoFn('GastosMensualesCreateFn','gastos-mensuales/create');
    const fnGmUpdate         = makeGoFn('GastosMensualesUpdateFn','gastos-mensuales/update');
    const fnGmDelete         = makeGoFn('GastosMensualesDeleteFn','gastos-mensuales/delete');
    const fnScheduler        = makeGoFn('SchedulerFn',             'scheduler');

    // ���── DynamoDB permissions ────────────────────────────────────────────────

    categoriasTable.grantReadData(fnCategList);
    categoriasTable.grantReadWriteData(fnCategCreate);
    participantesTable.grantReadData(fnPartList);
    participantesTable.grantReadWriteData(fnPartUpdate);
    gastosTable.grantReadData(fnGastosList);
    gastosTable.grantReadWriteData(fnGastosCreate);
    gastosMensualesTable.grantReadWriteData(fnGastosCreate);
    gastosTable.grantReadWriteData(fnGastosUpdate);
    gastosTable.grantReadWriteData(fnGastosVerificar);
    gastosTable.grantReadData(fnResumen);
    categoriasTable.grantReadData(fnResumen);
    participantesTable.grantReadData(fnResumen);
    transferenciasTable.grantReadData(fnResumen);
    transferenciasTable.grantReadData(fnTrList);
    transferenciasTable.grantReadWriteData(fnTrCreate);
    transferenciasTable.grantReadWriteData(fnTrDelete);
    gastosMensualesTable.grantReadData(fnGmList);
    gastosMensualesTable.grantReadWriteData(fnGmCreate);
    gastosMensualesTable.grantReadWriteData(fnGmUpdate);
    gastosMensualesTable.grantReadWriteData(fnGmDelete);
    gastosTable.grantReadWriteData(fnScheduler);
    gastosMensualesTable.grantReadWriteData(fnScheduler);

    // ─── EventBridge: run scheduler on 1st of every month at 06:00 UTC ──────

    const monthlyRule = new events.Rule(this, 'MonthlyScheduler', {
      ruleName: 'gastos-monthly-scheduler',
      schedule: events.Schedule.cron({ minute: '0', hour: '6', day: '1', month: '*', year: '*' }),
      description: 'Generates recurring gastos from plantillas on the 1st of each month',
    });
    monthlyRule.addTarget(new targets.LambdaFunction(fnScheduler));

    // ─── API Gateway ─────────────────────────────────────────────────────────

    const api = new apigateway.RestApi(this, 'GastosApi', {
      restApiName: 'GastosPersonalesApi',
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
        allowHeaders: ['Content-Type', 'Authorization'],
      },
    });

    const li = (fn: lambda.Function) => new apigateway.LambdaIntegration(fn);

    // /categorias
    const categorias = api.root.addResource('categorias');
    categorias.addMethod('GET',  li(fnCategList));
    categorias.addMethod('POST', li(fnCategCreate));

    // /participantes + /participantes/{id}
    const participantes = api.root.addResource('participantes');
    participantes.addMethod('GET', li(fnPartList));
    const participante = participantes.addResource('{id}');
    participante.addMethod('PUT', li(fnPartUpdate));

    // /gastos + /gastos/{id}/verificar
    const gastos = api.root.addResource('gastos');
    gastos.addMethod('GET',  li(fnGastosList));
    gastos.addMethod('POST', li(fnGastosCreate));
    const gastoById = gastos.addResource('{id}');
    gastoById.addMethod('PUT', li(fnGastosUpdate));
    const verificar = gastoById.addResource('verificar');
    verificar.addMethod('PUT', li(fnGastosVerificar));

    // /resumen
    const resumen = api.root.addResource('resumen');
    resumen.addMethod('GET', li(fnResumen));

    // /transferencias + /transferencias/{id}
    const transferencias = api.root.addResource('transferencias');
    transferencias.addMethod('GET',  li(fnTrList));
    transferencias.addMethod('POST', li(fnTrCreate));
    const transferenciaById = transferencias.addResource('{id}');
    transferenciaById.addMethod('DELETE', li(fnTrDelete));

    // /gastos-mensuales + /gastos-mensuales/{id}
    const gastosMensuales = api.root.addResource('gastos-mensuales');
    gastosMensuales.addMethod('GET',  li(fnGmList));
    gastosMensuales.addMethod('POST', li(fnGmCreate));
    const gastoMensualById = gastosMensuales.addResource('{id}');
    gastoMensualById.addMethod('PUT',    li(fnGmUpdate));
    gastoMensualById.addMethod('DELETE', li(fnGmDelete));

    new cdk.CfnOutput(this, 'ApiUrl', {
      value: api.url,
      description: 'API Gateway URL — update ApiClient.baseUrl in the Flutter app',
    });

    // ─── S3 + CloudFront para Flutter Web ────────────────────────────────────

    const webBucket = new s3.Bucket(this, 'WebBucket', {
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      encryption: s3.BucketEncryption.S3_MANAGED,
    });

    const webDistribution = new cloudfront.Distribution(this, 'WebDistribution', {
      defaultBehavior: {
        origin: origins.S3BucketOrigin.withOriginAccessControl(webBucket),
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
        cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
      },
      defaultRootObject: 'index.html',
      // SPA routing: 403/404 desde S3 → sirve index.html → Flutter maneja la ruta
      errorResponses: [
        { httpStatus: 403, responseHttpStatus: 200, responsePagePath: '/index.html' },
        { httpStatus: 404, responseHttpStatus: 200, responsePagePath: '/index.html' },
      ],
    });

    new cdk.CfnOutput(this, 'WebBucketName', {
      value: webBucket.bucketName,
      description: 'Sube el build web: aws s3 sync movil/build/web/ s3://BUCKET/ --delete',
    });

    new cdk.CfnOutput(this, 'WebUrl', {
      value: `https://${webDistribution.distributionDomainName}`,
      description: 'URL pública de la app web (CloudFront HTTPS)',
    });

    // ─── Build web de Flutter + subida automática a S3 ──────────────────────
    // Corre `flutter build web` localmente (requiere el SDK de Flutter en
    // la máquina que ejecuta `cdk deploy`) y sube el resultado al bucket,
    // invalidando CloudFront para que el cambio se vea de inmediato.

    const movilDir = path.join(__dirname, '../../../movil');

    new s3deploy.BucketDeployment(this, 'WebDeployment', {
      sources: [
        s3deploy.Source.asset(movilDir, {
          assetHashType: cdk.AssetHashType.OUTPUT,
          bundling: {
            local: {
              tryBundle(outputDir: string): boolean {
                try {
                  execSync('flutter build web --release', {
                    cwd: movilDir,
                    stdio: 'inherit',
                  });
                } catch (err) {
                  console.error('flutter build web falló — ¿está instalado Flutter en este equipo?', err);
                  return false;
                }
                execSync(`cp -R "${path.join(movilDir, 'build', 'web')}/." "${outputDir}/"`);
                return true;
              },
            },
            image: cdk.DockerImage.fromRegistry('alpine:3'),
            command: [
              'sh', '-c',
              'echo "No se pudo compilar Flutter Web localmente. Instala el SDK de Flutter y vuelve a intentar." && exit 1',
            ],
          },
        }),
      ],
      destinationBucket: webBucket,
      distribution: webDistribution,
      distributionPaths: ['/*'],
      // El build de Flutter web (~35-40MB descomprimido) excede la memoria
      // default (128MB) del Lambda de BucketDeployment y causa
      // Runtime.OutOfMemory — CloudFormation reintenta indefinidamente
      // hasta agotar el timeout. Subir memoria y /tmp evita ese loop.
      memoryLimit: 1024,
      ephemeralStorageSize: cdk.Size.mebibytes(1024),
    });
  }
}
