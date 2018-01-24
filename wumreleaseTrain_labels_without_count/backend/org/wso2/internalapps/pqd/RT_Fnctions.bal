package org.wso2.internalapps.pqd;



import ballerina.lang.jsons;
import ballerina.utils.logger;
import ballerina.lang.errors;
import ballerina.lang.files;
import ballerina.lang.blobs;
import ballerina.data.sql;
import ballerina.lang.time;
import ballerina.lang.datatables;
import ballerina.lang.system;




function getConfData (string filePath) (json) {

    files:File configFile = {path: filePath};

    try{
        files:open(configFile, "r");
        logger:debug(filePath + " file found");

    } catch (errors:Error err) {
        logger:error(filePath + " file not found. " + err.msg);
    }

    var content, numberOfBytes = files:read(configFile, 100000);
    logger:debug(filePath + " content read");

    files:close(configFile);
    logger:debug(filePath + " file closed");

    string configString = blobs:toString(content, "utf-8");

    try{
        json configJson = jsons:parse(configString);
        return configJson;

    } catch (errors:Error err) {
        logger:error("JSON syntax error found in "+ filePath + " " + err.msg);
        json configJson = jsons:parse(configString);
    }
    return null;

}
json confJson = getConfData("config.json");

function getDatabaseMap (json configData)(map) {

    string dbIP;
    int dbPort;
    string dbName;
    string dbUsername;
    string dbPassword;
    int poolSize;

    try {
        dbIP = jsons:getString(configData, "$.WUM_JDBC.DB_HOST");
        dbPort = jsons:getInt(configData, "$.WUM_JDBC.DB_PORT");
        dbName = jsons:getString(configData, "$.WUM_JDBC.DB_NAME");
        dbUsername = jsons:getString(configData, "$.WUM_JDBC.DB_USERNAME");
        dbPassword = jsons:getString(configData, "$.WUM_JDBC.DB_PASSWORD");
        poolSize = jsons:getInt(configData, "$.WUM_JDBC.MAXIMUM_POOL_SIZE");

    } catch (errors:Error err) {
        logger:error("Properties not defined in config.json: " + err.msg );
        dbIP = jsons:getString(configData, "$.WUM_JDBC.DB_HOST");
        dbPort = jsons:getInt(configData, "$.WUM_JDBC.DB_PORT");
        dbName = jsons:getString(configData, "$.WUM_JDBC.DB_NAME");
        dbUsername = jsons:getString(configData, "$.WUM_JDBC.DB_USERNAME");
        dbPassword = jsons:getString(configData, "$.WUM_JDBC.DB_PASSWORD");
        poolSize = jsons:getInt(configData, "$.WUM_JDBC.MAXIMUM_POOL_SIZE");

    }


    map propertiesMap={"jdbcUrl":"jdbc:mysql://"+dbIP+":"+dbPort+"/"+dbName, "username":dbUsername, "password":dbPassword, "maximumPoolSize":poolSize};

    return propertiesMap;

}
function createDBConnection()(sql:ClientConnector) {

    map props = getDatabaseMap(confJson);
    sql:ClientConnector rmDB = create sql:ClientConnector(props);
    return rmDB;
}
function epochToDate(int time,string zoneId, int zoneOffset )(string){
    time:Time releaseDate ={time:time, zone:{zoneId:zoneId,zoneOffset:zoneOffset}};
    string releaseDateString = time:format(releaseDate,"yyyy-MM-dd");
    return releaseDateString;
}


function getPqdDatabaseMap (json configData)(map) {

    string dbIP;
    int dbPort;
    string dbName;
    string dbUsername;
    string dbPassword;
    int poolSize;

    try {
        dbIP = jsons:getString(configData, "$.PQD_JDBC.DB_HOST");
        dbPort = jsons:getInt(configData, "$.PQD_JDBC.DB_PORT");
        dbName = jsons:getString(configData, "$.PQD_JDBC.DB_NAME");
        dbUsername = jsons:getString(configData, "$.PQD_JDBC.DB_USERNAME");
        dbPassword = jsons:getString(configData, "$.PQD_JDBC.DB_PASSWORD");
        poolSize = jsons:getInt(configData, "$.PQD_JDBC.MAXIMUM_POOL_SIZE");

    } catch (errors:Error err) {
        logger:error("Properties not defined in config.json: " + err.msg );
        dbIP = jsons:getString(configData, "$.PQD_JDBC.DB_HOST");
        dbPort = jsons:getInt(configData, "$.PQD_JDBC.DB_PORT");
        dbName = jsons:getString(configData, "$.PQD_JDBC.DB_NAME");
        dbUsername = jsons:getString(configData, "$.PQD_JDBC.DB_USERNAME");
        dbPassword = jsons:getString(configData, "$.PQD_JDBC.DB_PASSWORD");
        poolSize = jsons:getInt(configData, "$.PQD_JDBC.MAXIMUM_POOL_SIZE");

    }


    map propertiesMap={"jdbcUrl":"jdbc:mysql://"+dbIP+":"+dbPort+"/"+dbName, "username":dbUsername, "password":dbPassword, "maximumPoolSize":poolSize};

    return propertiesMap;

}
function createPqdDBConnection()(sql:ClientConnector) {

    map props = getPqdDatabaseMap(confJson);
    sql:ClientConnector rmDB = create sql:ClientConnector(props);
    return rmDB;
}


function getAllReleases(int startFormat, int endFormat)(json){


    sql:ClientConnector wumDB = createDBConnection();

    sql:Parameter[] params = [];
    sql:Parameter[] params1 = [];
    sql:Parameter[] params2 = [];
    sql:Parameter[] params3 = [];
    sql:Parameter[] params4 = [];
    sql:Parameter[] params5 = [];
    sql:Parameter[] params6 = [];
    sql:Parameter[] params7 = [];
    sql:Parameter[] params8 = [];
    sql:Parameter[] params9 = [];

    //time:Time startTime ={time:startFormat, zone:{zoneId:"Asia/Colombo",zoneOffset:19800}};
    //string start = time:format(startTime,"yyyy-MM-dd'T'HH:mm:ssz");
    //
    //time:Time endTime ={time:endFormat, zone:{zoneId:"Asia/Colombo",zoneOffset:19800}};
    //string end = time:format(endTime,"yyyy-MM-dd'T'HH:mm:ssz");


    sql:Parameter startTimeStamp = {sqlType:"varchar", value:startFormat};
    sql:Parameter endTimeStamp = {sqlType:"varchar", value:endFormat};

    params1=[startTimeStamp,endTimeStamp];
    datatable dtWUMReleaseDates = wumDB.select(GET_ALL_REDMINE_RELEASE_DATES, params1);

    var wumReleaseDatesJson, err = <json>dtWUMReleaseDates;
    //system:println(start);
    //system:println(end);
    system:println(wumReleaseDatesJson);
    logger:debug(wumReleaseDatesJson);
    datatables:close(dtWUMReleaseDates);

    json allReleases = [];
    var wumReleaseDatesCount = lengthof wumReleaseDatesJson;
    var wumLoopIndex = 0;
    var unicId=0;


    while (wumLoopIndex < wumReleaseDatesCount) {

        json data={};

        var id= wumLoopIndex + 1;

        var time, _=(string)wumReleaseDatesJson[wumLoopIndex].releaseDate;
        //string zoneId ="";
        //int zoneOffset =0;
        //var date= epochToDate(time, zoneId, zoneOffset);

        system:println(time);

        sql:Parameter wumReleaseDate = {sqlType:"varchar", value:time};
        params2=[wumReleaseDate];

        datatable dtWUMReleaseDetails = wumDB.select(GET_REDMINE_RELEASE_DETAILS, params2);
        var wumReleaseDetailsJson, err = <json>dtWUMReleaseDetails;
        system:println(wumReleaseDetailsJson);
        logger:debug(wumReleaseDetailsJson);
        datatables:close(dtWUMReleaseDetails);

        var wumReleaseDetailsLength = lengthof wumReleaseDetailsJson;
        var wumReleaseIndex = 0;



        while (wumReleaseIndex < wumReleaseDetailsLength) {
            sql:ClientConnector pqdDB = createPqdDBConnection();

            var product, _= (string)wumReleaseDetailsJson[wumReleaseIndex].productName;

            sql:Parameter productName = {sqlType:"varchar", value:product};
            params3=[productName];

            datatable dtProductAreas = pqdDB.select("SELECT PRODUCT_AREA_NAME AS productArea FROM  WUM_PRODUCT_TO_AREA_MAPPING Where PRODUCT_NAME=? ;", params3);
            var productAreasJson, err = <json>dtProductAreas;

            system:print("Area : ");
            system:println(productAreasJson);


            unicId=unicId + 1;

            wumReleaseDetailsJson[wumReleaseIndex].id = unicId;//create a unic number
            var color="";

            var area, _=(string)productAreasJson[0].productArea;
            //var area = "apim";
            var productVersion, _=(int)wumReleaseDetailsJson[wumReleaseIndex].productVersion;

            var bugFixesString, _=(string )wumReleaseDetailsJson[wumReleaseIndex].bugFixesJson;
            var bugFixesJson=jsons:parse(bugFixesString);

            var key ="-";
            var url ="-";
            var desc ="-";

            if(lengthof bugFixesJson > 0){
                system:println(bugFixesJson);
                key, _ = (string)bugFixesJson[0].key;
                url, _ = (string)bugFixesJson[0].url;
                desc, _ = (string)bugFixesJson[0].desc;
            }
            system:println(bugFixesJson);
            system:println(lengthof bugFixesJson);
            system:println(key);
            system:println(url);
            system:println(desc);

            if (area=="apim"){
                color="green";
            }else if(area=="analytics"){
                color="red";
            }else if(area=="cloud"){
                color="blue";
            }else if(area=="integration"){
                color="purple";
            }else if(area=="iot"){
                color="skyblue";
            }else if(area=="identity"){
                color="orange";
            }else if(area=="other"){
                color="black";
            }

            wumReleaseDetailsJson[wumReleaseIndex].bugKey = key;
            wumReleaseDetailsJson[wumReleaseIndex].bugUrl = url;
            wumReleaseDetailsJson[wumReleaseIndex].bugDescription = desc;
            wumReleaseDetailsJson[wumReleaseIndex].color = color;
            wumReleaseDetailsJson[wumReleaseIndex].start = time;
            wumReleaseIndex = wumReleaseIndex + 1;

            pqdDB.close();
        }

        data.id=id;
        data.releases= wumReleaseDetailsJson;
        data.start=time;
        data.class="blue";

        allReleases[wumLoopIndex] = data;


        wumLoopIndex = wumLoopIndex + 1;
    }

    wumDB.close();
    return allReleases;
}
function getReleasesByProductArea (string productArea, int startFormat, int endFormat) (json) {

    sql:Parameter[] params3 = [];
    sql:ClientConnector pqdDB = createPqdDBConnection();

    sql:Parameter productAreaName = {sqlType:"varchar", value:productArea};
    params3=[productAreaName];
    datatable dtProductNames = pqdDB.select("SELECT PRODUCT_NAME FROM  WUM_PRODUCT_TO_AREA_MAPPING Where PRODUCT_AREA_NAME=? ;", params3);
    var productNamesJson, err = <json>dtProductNames;

    system:print("Product : ");
    system:println(productNamesJson);

    pqdDB.close();


    string productArray = "\'";

    system:println("productNamesJson");

    var productLength =lengthof productNamesJson;
    var productIndex = 0;
    while (productIndex<productLength ){
        var currentProduct, _=(string )productNamesJson[productIndex].PRODUCT_NAME;
        if(productIndex != (productLength -1)){
            productArray = productArray + currentProduct + "\',\'";
        }else{
            productArray = productArray + currentProduct + "\'";
        }

        productIndex = productIndex +1;
    }

    system:println(productArray);



    sql:ClientConnector wumDB = createDBConnection();

    sql:Parameter[] params = [];
    sql:Parameter[] params1 = [];
    sql:Parameter[] params2 = [];

    sql:Parameter[] params4 = [];
    sql:Parameter[] params5 = [];
    sql:Parameter[] params6 = [];
    sql:Parameter[] params7 = [];
    sql:Parameter[] params8 = [];
    sql:Parameter[] params9 = [];




    //var productArray1 = "'wso2am','wso2am-analytics'";

    sql:Parameter productNames = {sqlType:"varchar", value:productArray};
    sql:Parameter startTimeStamp = {sqlType:"varchar", value:startFormat};
    sql:Parameter endTimeStamp = {sqlType:"varchar", value:endFormat};

    params1=[startTimeStamp, endTimeStamp];//
    datatable dtWUMReleaseDates = wumDB.select("SELECT distinct date(from_unixtime(floor(timestamp/1000))) AS releaseDate FROM updates where  product_name in ("+ productArray +") and timestamp >= ? AND timestamp <= ? ", params1);

    var wumReleaseDatesJson, err = <json>dtWUMReleaseDates;
    logger:debug(wumReleaseDatesJson);
    datatables:close(dtWUMReleaseDates);
    system:println(wumReleaseDatesJson);

    json allReleases = [];
    var wumReleaseDatesCount = lengthof wumReleaseDatesJson;
    var wumLoopIndex = 0;
    var unicId=0;
    while (wumLoopIndex < wumReleaseDatesCount) {

        json data={};

        var id= wumLoopIndex + 1;
        var time, _=(string)wumReleaseDatesJson[wumLoopIndex].releaseDate;
        system:println(wumReleaseDatesJson);
        system:println(time);
        //string zoneId ="";
        //int zoneOffset =0;
        //var date= epochToDate(time, zoneId, zoneOffset);

        sql:Parameter wumReleaseDate = {sqlType:"varchar", value:time};
        params2=[ wumReleaseDate];



        datatable dtWUMReleaseDetails = wumDB.select("SELECT kernel_version AS kernalVersion, platform_version AS platformVersion, product_name AS productName, product_version AS productVersion, description AS description, applies_to AS appliesTo, bug_fixes AS bugFixesJson  FROM
        updates where product_name in ("+ productArray +") AND date(from_unixtime(floor(timestamp/1000)))= ?;", params2);
        var wumReleaseDetailsJson, err = <json>dtWUMReleaseDetails;
        logger:debug(wumReleaseDetailsJson);
        datatables:close(dtWUMReleaseDetails);
        system:println(wumReleaseDetailsJson);

        var wumReleaseDetailsLength = lengthof wumReleaseDetailsJson;
        var wumReleaseIndex = 0;


        while (wumReleaseIndex < wumReleaseDetailsLength) {
            unicId=unicId + 1;
            wumReleaseDetailsJson[wumReleaseIndex].id = unicId;//create a unic number
            var color="";
            var area = productArea;
            var productVersion, _=(int)wumReleaseDetailsJson[wumReleaseIndex].productVersion;

            var bugFixesString, _=(string )wumReleaseDetailsJson[wumReleaseIndex].bugFixesJson;
            var bugFixesJson=jsons:parse(bugFixesString);

            var key ="-";
            var url ="-";
            var desc ="-";

            if(lengthof bugFixesJson > 0){
                system:println(bugFixesJson);
                key, _ = (string)bugFixesJson[0].key;
                url, _ = (string)bugFixesJson[0].url;
                desc, _ = (string)bugFixesJson[0].desc;
            }
            system:println(bugFixesJson);
            system:println(lengthof bugFixesJson);
            system:println(key);
            system:println(url);
            system:println(desc);

            if (area=="apim"){
                color="green";
            }else if(area=="analytics"){
                color="red";
            }else if(area=="cloud"){
                color="blue";
            }else if(area=="integration"){
                color="purple";
            }else if(area=="iot"){
                color="skyblue";
            }else if(area=="identity"){
                color="orange";
            }else if(area=="other"){
                color="black";
            }

            wumReleaseDetailsJson[wumReleaseIndex].bugKey = key;
            wumReleaseDetailsJson[wumReleaseIndex].bugUrl = url;
            wumReleaseDetailsJson[wumReleaseIndex].bugDescription = desc;
            wumReleaseDetailsJson[wumReleaseIndex].color = color;
            wumReleaseDetailsJson[wumReleaseIndex].start = time;
            wumReleaseIndex = wumReleaseIndex + 1;

        }

        data.id=id;
        data.releases= wumReleaseDetailsJson;
        data.start=time;
        data.class="blue";

        allReleases[wumLoopIndex] = data;


        wumLoopIndex = wumLoopIndex + 1;
    }

    wumDB.close();
    return allReleases;
}


function test(){
    time:Time releaseDate =time:currentTime();
    system:println(releaseDate);


    time:Time releaseDate1 ={time:1513407169218, zone:{zoneId:"",zoneOffset:0}};
    system:println(releaseDate1);


    string releaseDateString = time:format(releaseDate,"yyyy-MM-dd'T'HH:mm:ssz");
    system:println(releaseDateString);


    string releaseDate1String = time:format(releaseDate1,"yyyy-MM-dd'T'HH:mm:ssz");
    system:println(releaseDate1String);

}


