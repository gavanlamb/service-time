package io.expensely.jmeter;

import org.apache.jmeter.config.Arguments;
import org.apache.jmeter.engine.StandardJMeterEngine;
import org.apache.jmeter.report.config.ConfigurationException;
import org.apache.jmeter.report.dashboard.GenerationException;
import org.apache.jmeter.report.dashboard.ReportGenerator;
import org.apache.jmeter.reporters.ResultCollector;
import org.apache.jmeter.reporters.Summariser;
import org.apache.jmeter.save.SaveService;
import org.apache.jmeter.util.JMeterUtils;
import org.apache.jorphan.collections.HashTree;
import org.apache.jorphan.collections.SearchByClass;

import java.io.File;
import java.util.Collection;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

public class JMeterRunner {

    public static void main(String[] argv) throws Exception {
        String path = System.getenv("PWD");

        JMeterUtils.loadJMeterProperties(path + "/libraries/apache-jmeter-5.4.3/bin/jmeter.properties");
        JMeterUtils.setJMeterHome(path + "/libraries/apache-jmeter-5.4.3");
        JMeterUtils.initLocale();
        JMeterUtils.initLogging();
        SaveService.loadProperties();

        // Load JMX
        Boolean exportHtmlReport = Boolean.parseBoolean(System.getenv("JMETER_EXPORT_HTML"));
        StandardJMeterEngine jMeter = new StandardJMeterEngine();
        File loadTestFile = new File(path + "/out/production/Time.Jmeter/io/expensely/time/load.jmx");
        HashTree testPlanTree = SaveService.loadTree(loadTestFile);

        AddArguments(testPlanTree);
        AddReporting(testPlanTree, path);

        jMeter.configure(testPlanTree);
        jMeter.run();
        jMeter.reset();
        jMeter.exit();

        UploadToS3(path);
    }

    private static HashMap<String, String> GetArguments(){
        Map<String,String> environmentVariables = System.getenv();

        HashMap<String, String> arguments = new HashMap<>();

        for (String key : environmentVariables.keySet())
        {
            if(key.startsWith("JMETER_VARIABLE_"))
            {
                String name = key.replace("JMETER_VARIABLE_","").toLowerCase(Locale.ROOT);
                String value = environmentVariables.get(key);
                arguments.put(name, value);
            }
        }

        return arguments;
    }

    private static void UploadToS3(
        String path){
        Boolean uploadToS3 = Boolean.parseBoolean(System.getenv("UPLOAD_TO_S3"));
        if(uploadToS3){

        }
    }

    private static void AddArguments(
        HashTree testPlanTree){
        HashMap<String, String> arguments = GetArguments();
        if(arguments.size() > 0){
            SearchByClass<Arguments> udvSearch = new SearchByClass<>(Arguments.class);
            testPlanTree.traverse(udvSearch);
            Collection<Arguments> udvs = udvSearch.getSearchResults();
            Arguments args = udvs.stream().findAny().orElseGet(Arguments::new);
            arguments.keySet().forEach(key -> args.addArgument(key, arguments.get(key)));
        }
    }

    private static void AddReporting(
        HashTree testPlanTree,
        String path) throws ConfigurationException, GenerationException {

        Summariser summer = null;
        String summariserName = JMeterUtils.getPropDefault("summariser.name", "summary");
        if (summariserName.length() > 0) {
            summer = new Summariser(summariserName);
        }
        ResultCollector logger = new ResultCollector(summer);
        testPlanTree.add(testPlanTree.getArray()[0], logger);

        Boolean exportHtmlReport = Boolean.parseBoolean(System.getenv("JMETER_EXPORT_HTML"));
        if(exportHtmlReport){
            JMeterUtils.setProperty("jmeter.reportgenerator.exporter.html.classname", "org.apache.jmeter.report.dashboard.HtmlTemplateExporter");
            JMeterUtils.setProperty("jmeter.reportgenerator.exporter.html.property.output_dir", "report-output/dashboard");
            String logFile = path + "/results.jtl";
            logger.setFilename(logFile);
            ReportGenerator generator = new ReportGenerator(logFile, null);
            generator.generate();
        }
    }
}
