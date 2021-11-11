import { run } from 'newman';
import * as aws from 'aws-sdk';
import * as fs from "fs";
import apiCollection from './collections/Time.API.postman_collection.json';
import localEnvironmentVariables from './environments/Time.Local.postman_environment.json';
import previewEnvironmentVariables from './environments/Time.Preview.postman_environment.json';
import productionEnvironmentVariables from './environments/Time.Production.postman_environment.json';

const codeDeploy = new aws.CodeDeploy({apiVersion: '2014-10-06'});
const s3 = new aws.S3();

const variableMap: {[key: string]: any } = {
    Local: localEnvironmentVariables,
    Preview: previewEnvironmentVariables,
    Production: productionEnvironmentVariables
}
const environment = (process.env.ENVIRONMENT ?? "Local") as string;
const buildNumber = process.env.BUILD_NUMBER as string;
const resultsBucket = process.env.RESULTS_BUCKET as string;
const baseUrl = process.env.BASEURL as string;

export const handler = async (event: { DeploymentId: any; LifecycleEventHookExecutionId: any; }, context: any, callback: any) => {
    const deploymentId = event.DeploymentId;
    const lifecycleEventHookExecutionId = event.LifecycleEventHookExecutionId;
    const resultsFile = `results.${buildNumber}.xml`;
    const environmentConfiguration = environment.startsWith("Preview") ? variableMap["Preview"] : variableMap[environment]
    run(
        {
            // @ts-ignore
            abortOnFailure: true,
            collection: apiCollection,
            envVar: [
                // @ts-ignore
                {
                    "key": "baseUrl",
                    "value": baseUrl
                }
            ],
            environment: environmentConfiguration,
            reporters: ['cli', 'junitfull'],
            reporter: {
                junitfull: {
                    export: `/tests/${resultsFile}`,
                },
            },
        },
        async (error: any, data: any) => {
            if (resultsBucket) {
                const testResultsData = fs.readFileSync(`/tests/${resultsFile}`, 'utf8');
                await s3.upload({
                    ContentType: "application/xml",
                    Bucket: resultsBucket,
                    Body: testResultsData,
                    Key: `/${environment}/Time.Api/${resultsFile}`
                }).promise()
            }
            if (error) {
                console.error(error)
                const params = {
                    deploymentId,
                    lifecycleEventHookExecutionId,
                    status: 'Failed'
                };
                codeDeploy.putLifecycleEventHookExecutionStatus(params, () => {
                    callback("Error encountered during test run");
                });
            } else {
                console.log(data)
                const params = {
                    deploymentId,
                    lifecycleEventHookExecutionId,
                    status: 'Succeeded'
                };
                codeDeploy.putLifecycleEventHookExecutionStatus(params, () => {
                    callback();
                });
            }
        }
    );
}
