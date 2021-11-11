import { run } from 'newman';
import * as aws from 'aws-sdk';
import * as fs from "fs";
import apiCollection from './collections/Time.API.postman_collection.json';
import localEnvironmentVariables from './environments/Time.Local.postman_environment.json';
import previewEnvironmentVariables from './environments/Time.Preview.postman_environment.json';
import productionEnvironmentVariables from './environments/Time.Production.postman_environment.json';

const variableMap: {[key: string]: string } = {
    Local: JSON.stringify(localEnvironmentVariables),
    Preview: JSON.stringify(previewEnvironmentVariables),
    Production: JSON.stringify(productionEnvironmentVariables)
}
const environment = (process.env.ENVIRONMENT ?? "Local") as string;
const buildNumber = process.env.BUILD_NUMBER as string;
const resultsBucket = process.env.RESULTS_BUCKET as string;
const baseUrl = process.env.BASEURL as string;

export const handler = (event: any): void => {
    try {
        const codeDeploy = new aws.CodeDeploy({apiVersion: '2014-10-06'});
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
                reporters: 'junitfull',
                reporter: {
                    junitfull: {
                        export: `/tests/${resultsFile}`,
                    },
                },
            },
            (error: any, data: any) => {
                // if (resultsBucket) {
                //     const s3 = new aws.S3();
                //     const testResultsData = fs.readFileSync(`/tests/${resultsFile}`, 'utf8');
                //     s3.upload({
                //         ContentType: "application/xml",
                //         Bucket: resultsBucket,
                //         Body: testResultsData,
                //         Key: `/${environment}/Time.Api/${resultsFile}`
                //     });
                // }
                if (error) {
                    console.error(error)
                    const params = {
                        deploymentId: event.DeploymentId,
                        lifecycleEventHookExecutionId: event.LifecycleEventHookExecutionId,
                        status: 'Failed'
                    };
                    codeDeploy.putLifecycleEventHookExecutionStatus(params);
                } else {
                    const params = {
                        deploymentId: event.DeploymentId,
                        lifecycleEventHookExecutionId: event.LifecycleEventHookExecutionId,
                        status: 'Succeeded'
                    };
                    codeDeploy.putLifecycleEventHookExecutionStatus(params);
                }
            }
        );
    } catch (error) {
        console.error(error);
    }
}
