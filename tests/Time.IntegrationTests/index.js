'use strict';

const newman = require('newman');
const aws = require('aws-sdk');
const fs = require("fs");

exports.handler = (event, context, callback) => {
    const environment = (process.env.ENVIRONMENT ?? "local");
    const buildNumber = process.env.BUILD_NUMBER;
    const resultsBucket = process.env.RESULTS_BUCKET;
    const baseUrl = process.env.BASEURL;
    
    const codeDeploy = new aws.CodeDeploy({apiVersion: '2014-10-06'});
    const resultsFile = `${buildNumber}.xml`;
    newman.run(
        {
            abortOnFailure: true,
            abortOnError: true,
            collection: './collections/time.postman_collection.json',
            delayRequest: 1000,
            envVar: [
                {
                    "key": "baseUrl",
                    "value": baseUrl
                }
            ],
            environment: `./environments/${environment.startsWith("preview") ? "preview" : environment}.postman_environment.json`,
            reporters: 'junitfull',
            reporter: {
                junitfull: {
                    export: `/tmp/${resultsFile}`,
                },
            },
        },
        (newmanError, newmanData) => {
            console.log(newmanError);
            console.log(newmanData);
            if (resultsBucket) {
                const s3 = new aws.S3();
                const testResultsData = fs.readFileSync(`/tmp/${resultsFile}`, 'utf8');
                s3.upload(
                    {
                        ContentType: "application/xml",
                        Bucket: resultsBucket,
                        Body: testResultsData,
                        Key: `time/${environment}/${resultsFile}`
                    },
                    function (s3Error, s3Data) {
                        if (s3Error) {
                            console.error(JSON.stringify(s3Error));
                        } else if (s3Data) {
                            console.log(JSON.stringify(s3Data));
                        } 
                        
                        if (newmanError || (newmanData.failures && newmanData.failures.length > 0)) {
                            console.error(JSON.stringify(newmanError));
                            console.error(JSON.stringify(newmanData));
                            const params = {
                                deploymentId: event.DeploymentId,
                                lifecycleEventHookExecutionId: event.LifecycleEventHookExecutionId,
                                status: 'Failed'
                            };
                            codeDeploy.putLifecycleEventHookExecutionStatus(
                                params,
                                function (codeDeployError, codeDeployData) {
                                    if (codeDeployError) {
                                        console.error(codeDeployError);
                                        callback('Validation test failed');
                                    } else {
                                        console.log(codeDeployData);
                                        callback(null, 'Validation test succeeded');
                                    }
                                });
                        } else {
                            console.log(JSON.stringify(newmanData));
                            const params = {
                                deploymentId: event.DeploymentId,
                                lifecycleEventHookExecutionId: event.LifecycleEventHookExecutionId,
                                status: 'Succeeded'
                            };
                            codeDeploy.putLifecycleEventHookExecutionStatus(
                                params,
                                function (codeDeployError, codeDeployData) {
                                    if (codeDeployError) {
                                        console.error(codeDeployError);
                                        callback('Validation test failed');
                                    } else {
                                        console.log(codeDeployData);
                                        callback(null, 'Validation test succeeded');
                                    }
                                });
                        }
                    });
            }
        }
    );
}
