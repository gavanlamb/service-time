import { run } from 'newman';
import aws from 'aws-sdk';
import apiCollection from './collections/Time.API.postman_collection.json';
import localEnvironmentVariables from './environments/Time.Local.postman_environment.json';
import previewEnvironmentVariables from './environments/Time.Preview.postman_environment.json';
import productionEnvironmentVariables from './environments/Time.Production.postman_environment.json';

const variableMap: {[key: string]: any } = {
    Local: localEnvironmentVariables,
    Preview: previewEnvironmentVariables,
    Production: productionEnvironmentVariables
}
const environment = (process.env.Environment ?? "Local") as string;
const buildNumber = process.env.BuildNumber as string;
const resultsBucket = process.env.ResultsBucket as string;

export const handler = async (event: { DeploymentId: any; LifecycleEventHookExecutionId: any; }, context: any, callback: any) => {

    const codedeploy = new aws.CodeDeploy({apiVersion: '2014-10-06'});
    const deploymentId = event.DeploymentId;
    const lifecycleEventHookExecutionId = event.LifecycleEventHookExecutionId;

    run(
        {
            // @ts-ignore
            abortOnFailure: true,
            collection: apiCollection,
            environment: variableMap[environment],
            reporters: ['cli', 'junitfull'],
            reporter: {
                junitfull: {
                    export: '/tests/results.xml',
                },
            },
        },
        (error: any, data: any) => {
            // TODO Upload results file to s3 if not local
            if (error) {
                console.error(error)
                const params = {
                    deploymentId,
                    lifecycleEventHookExecutionId,
                    status: 'Failed'
                };
                codedeploy.putLifecycleEventHookExecutionStatus(params, () => {
                    callback("Error encountered during test run");
                });
            } else {
                console.log(data)
                const params = {
                    deploymentId,
                    lifecycleEventHookExecutionId,
                    status: 'Succeeded'
                };
                codedeploy.putLifecycleEventHookExecutionStatus(params, () => {
                    callback();
                });
            }
        }
    );
}
