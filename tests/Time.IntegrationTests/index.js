'use strict';

const newman = require('newman');
const aws = require('aws-sdk');

const environment = (process.env.ENVIRONMENT ?? "Local").startsWith("Preview") ? "Preview" : (process.env.ENVIRONMENT ?? "Local");
const buildNumber = process.env.BUILD_NUMBER;
//const resultsBucket = process.env.RESULTS_BUCKET;
const baseUrl = process.env.BASEURL;

exports.handler = (event) => {
    try {
        const codeDeploy = new aws.CodeDeploy({apiVersion: '2014-10-06'});
        const resultsFile = `results.${buildNumber}.xml`;
        newman.run(
            {
                abortOnFailure: true,
                collection: './collections/Time.API.postman_collection.json',
                envVar: [
                    {
                        "key": "baseUrl",
                        "value": baseUrl
                    }
                ],
                environment: `./environments/Time.${environment}.postman_environment.json`,
                reporters: ['cli','junitfull'],
                reporter: {
                    junitfull: {
                        export: `/tests/${resultsFile}`,
                    },
                },
            },
            (error, data) => {
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
                    console.error(error);
                    const params = {
                        deploymentId: event.DeploymentId,
                        lifecycleEventHookExecutionId: event.LifecycleEventHookExecutionId,
                        status: 'Failed'
                    };
                    codeDeploy.putLifecycleEventHookExecutionStatus(params);
                } else {
                    console.log(data);
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
