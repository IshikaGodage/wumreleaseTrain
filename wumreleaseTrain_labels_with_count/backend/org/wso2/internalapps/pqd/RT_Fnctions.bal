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


function getAllReleases1(int startFormat, int endFormat)(json){


    sql:ClientConnector wumDB = createDBConnection();

    sql:Parameter[] params = [];
    sql:Parameter[] params1 = [];


    sql:Parameter startTimeStamp = {sqlType:"varchar", value:startFormat};
    sql:Parameter endTimeStamp = {sqlType:"varchar", value:endFormat};

    params1=[startTimeStamp,endTimeStamp];
    datatable dtWUMReleaseCountDetails = wumDB.select("SELECT count(id)AS releasesCount,date(from_unixtime(floor(timestamp/1000))) AS releaseDate, product_name AS productName, product_version AS productVersion FROM updatesdb_200_wso2um.updates where timestamp >= ?  AND timestamp <= ? group by date(from_unixtime(floor(timestamp/1000))), product_name, product_version order by date(from_unixtime(floor(timestamp/1000))), product_name, product_version;", params1);
    var wumReleaseCountDetailsJson, err = <json>dtWUMReleaseCountDetails;
    system:println(wumReleaseCountDetailsJson);
    logger:debug(wumReleaseCountDetailsJson);
    datatables:close(dtWUMReleaseCountDetails);

    datatable dtWUMReleaseDetails = wumDB.select("SELECT  update_no AS updateNo, kernel_version AS kernalVersion, platform_version AS platformVersion, date(from_unixtime(floor(timestamp/1000))) AS releaseDate, product_name AS productName, product_version AS productVersion, description AS description, applies_to AS appliesTo, bug_fixes AS bugFixesJson FROM updatesdb_200_wso2um.updates where timestamp >= ?  AND timestamp <= ? order by date(from_unixtime(floor(timestamp/1000))), product_name, product_version  ;", params1);
    var wumReleaseDetailsJson, err = <json>dtWUMReleaseDetails;
    system:println(wumReleaseDetailsJson);
    logger:debug(wumReleaseDetailsJson);
    datatables:close(dtWUMReleaseDetails);

    sql:ClientConnector pqdDB = createPqdDBConnection();
    datatable dtProductAreas = pqdDB.select("SELECT PRODUCT_NAME AS productName, PRODUCT_AREA_NAME AS productArea, PRODUCT_AREA_COLOR AS productColor FROM  WUM_PRODUCT_TO_AREA_MAPPING;", params);
    var productAreasJson, err = <json>dtProductAreas;
    system:println(productAreasJson);
    logger:debug(productAreasJson);
    datatables:close(dtProductAreas);
    var productAreasJsonCount = lengthof productAreasJson;





    json allReleases = [];
    var cardId=0;
    var labelDataArrayIndex =0;
    json labelDataArray =[];

    json data ={};


    var wumReleaseCountDetailsCount = lengthof wumReleaseCountDetailsJson;
    system:println(wumReleaseCountDetailsCount);

    var wumLoopIndex = 0;
    var unicId=0;

    string releaseDateMem ="";
    string productNameMem ="";
    string productVersionMem ="";

    while (wumLoopIndex < wumReleaseCountDetailsCount) {

        system:println("Inside while");

        var releaseDate, _ = (string)wumReleaseCountDetailsJson[wumLoopIndex].releaseDate;
        var productName, _ = (string)wumReleaseCountDetailsJson[wumLoopIndex].productName;
        var productVersion, _ = (string)wumReleaseCountDetailsJson[wumLoopIndex].productVersion;
        var releasesCount, _ = (int)wumReleaseCountDetailsJson[wumLoopIndex].releasesCount;

        if(releaseDateMem != releaseDate){

            system:println("Inside if");

            if(releaseDateMem != ""){

                system:println(labelDataArray);
                data.labelDataArray=labelDataArray;
                allReleases[cardId-1]=data;
                system:println(allReleases);

            }
            releaseDateMem=releaseDate;
            cardId=cardId + 1;

            data={};
            data.id= cardId;
            data.start= releaseDateMem;

            labelDataArray =[];


            labelDataArrayIndex=0;



        }

        json labelData={};
        labelData.id = wumLoopIndex +1;
        labelData.releaseDate = releaseDate;
        labelData.productName = productName;
        labelData.productVersion = productVersion;
        labelData.releasesCount = releasesCount;

        var productAreaIndex=0;
        while(productAreaIndex<productAreasJsonCount){
            var productArea_m, _ = (string)productAreasJson[productAreaIndex].productArea;
            var productName_m, _ = (string)productAreasJson[productAreaIndex].productName;
            var productColor_m, _ = (string)productAreasJson[productAreaIndex].productColor;

            if(productName==productName_m){
                labelData.productArea = productArea_m;
                labelData.productColor = productColor_m;
            }

            productAreaIndex = productAreaIndex + 1;
        }


        var detailsIndex=0;
        json details =[];
        var wumReleaseDetailsCount = lengthof wumReleaseDetailsJson;
        var dataRowIndex = 0;
        //while(detailsIndex<wumReleaseDetailsCount){
        while(detailsIndex<lengthof wumReleaseDetailsJson){
            system:println(lengthof wumReleaseDetailsJson);
            var flag = false;

            json dataRow = {};
            var releaseDate_d, _ = (string)wumReleaseDetailsJson[detailsIndex].releaseDate;
            var productName_d, _ = (string)wumReleaseDetailsJson[detailsIndex].productName;
            var productVersion_d, _ = (string)wumReleaseDetailsJson[detailsIndex].productVersion;

            if(releaseDate==releaseDate_d && productName==productName_d && productVersion==productVersion_d){
                flag=true;
                dataRow.id=dataRowIndex +1;
                //dataRow.id=wumReleaseDetailsJson[detailsIndex].updateNo;
                dataRow.releaseDate=releaseDate_d;
                dataRow.productName=productName_d;
                dataRow.productVersion=productVersion_d;
                dataRow.kernalVersion=wumReleaseDetailsJson[detailsIndex].kernalVersion;
                dataRow.platformVersion=wumReleaseDetailsJson[detailsIndex].platformVersion;
                dataRow.appliesTo=wumReleaseDetailsJson[detailsIndex].appliesTo;
                dataRow.description=wumReleaseDetailsJson[detailsIndex].description;

                var bugFixesString, _=(string )wumReleaseDetailsJson[detailsIndex].bugFixesJson;
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

                dataRow.bugKey = key;
                dataRow.bugUrl = url;
                dataRow.bugDescription = desc;

                details[dataRowIndex]=dataRow;
                dataRowIndex = dataRowIndex +1;
            }
            if(flag){
                jsons:remove(wumReleaseDetailsJson, "$["+detailsIndex+"]");
            }else{
                detailsIndex = detailsIndex+1;
            }

        }

        labelData.details=details;

        labelDataArray[labelDataArrayIndex]=labelData;
        labelDataArrayIndex = labelDataArrayIndex +1;



        wumLoopIndex = wumLoopIndex +1;

        if(wumLoopIndex==wumReleaseCountDetailsCount){
            system:println(labelDataArray);
            data.labelDataArray=labelDataArray;
            allReleases[cardId-1]=data;
            system:println(allReleases);
        }


    }



    //while (wumLoopIndex < wumReleaseCountDetailsCount) {
    //
    //    json data={};
    //    var id= wumLoopIndex + 1;
    //
    //    var time, _=(string)wumReleaseDatesJson[wumLoopIndex].releaseDate;
    //    //string zoneId ="";
    //    //int zoneOffset =0;
    //    //var date= epochToDate(time, zoneId, zoneOffset);
    //
    //    system:println(time);
    //
    //    sql:Parameter wumReleaseDate = {sqlType:"varchar", value:time};
    //    params2=[wumReleaseDate];
    //
    //    datatable dtWUMReleaseDetails = wumDB.select(GET_REDMINE_RELEASE_DETAILS, params2);
    //    var wumReleaseDetailsJson, err = <json>dtWUMReleaseDetails;
    //    system:println(wumReleaseDetailsJson);
    //    logger:debug(wumReleaseDetailsJson);
    //    datatables:close(dtWUMReleaseDetails);
    //
    //    var wumReleaseDetailsLength = lengthof wumReleaseDetailsJson;
    //    var wumReleaseIndex = 0;
    //
    //
    //
    //    while (wumReleaseIndex < wumReleaseDetailsLength) {
    //        sql:ClientConnector pqdDB = createPqdDBConnection();
    //
    //        var product, _= (string)wumReleaseDetailsJson[wumReleaseIndex].productName;
    //
    //        sql:Parameter productName = {sqlType:"varchar", value:product};
    //        params3=[productName];
    //
    //        datatable dtProductAreas = pqdDB.select("SELECT PRODUCT_AREA_NAME AS productArea FROM  WUM_PRODUCT_TO_AREA_MAPPING Where PRODUCT_NAME=? ;", params3);
    //        var productAreasJson, err = <json>dtProductAreas;
    //
    //        system:print("Area : ");
    //        system:println(productAreasJson);
    //
    //
    //        unicId=unicId + 1;
    //
    //        wumReleaseDetailsJson[wumReleaseIndex].id = unicId;//create a unic number
    //        var color="";
    //
    //        var area, _=(string)productAreasJson[0].productArea;
    //        //var area = "apim";
    //        var productVersion, _=(int)wumReleaseDetailsJson[wumReleaseIndex].productVersion;
    //
    //        //var bugFixesString, _=(string )wumReleaseDetailsJson[wumReleaseIndex].bugFixesJson;
    //        //var bugFixesJson=jsons:parse(bugFixesString);
    //
    //        //var key ="-";
    //        //var url ="-";
    //        //var desc ="-";
    //        //
    //        //if(lengthof bugFixesJson > 0){
    //        //    system:println(bugFixesJson);
    //        //    key, _ = (string)bugFixesJson[0].key;
    //        //    url, _ = (string)bugFixesJson[0].url;
    //        //    desc, _ = (string)bugFixesJson[0].desc;
    //        //}
    //        //system:println(bugFixesJson);
    //        //system:println(lengthof bugFixesJson);
    //        //system:println(key);
    //        //system:println(url);
    //        //system:println(desc);
    //
    //        if (area=="apim"){
    //            color="green";
    //        }else if(area=="analytics"){
    //            color="red";
    //        }else if(area=="cloud"){
    //            color="blue";
    //        }else if(area=="integration"){
    //            color="purple";
    //        }else if(area=="iot"){
    //            color="skyblue";
    //        }else if(area=="identity"){
    //            color="orange";
    //        }else if(area=="other"){
    //            color="black";
    //        }
    //
    //        //wumReleaseDetailsJson[wumReleaseIndex].bugKey = key;
    //        //wumReleaseDetailsJson[wumReleaseIndex].bugUrl = url;
    //        //wumReleaseDetailsJson[wumReleaseIndex].bugDescription = desc;
    //        wumReleaseDetailsJson[wumReleaseIndex].color = color;
    //        wumReleaseDetailsJson[wumReleaseIndex].start = time;
    //        wumReleaseIndex = wumReleaseIndex + 1;
    //
    //        pqdDB.close();
    //    }
    //
    //    data.id=id;
    //    data.releases= wumReleaseDetailsJson;
    //    data.start=time;
    //    data.class="blue";
    //
    //    allReleases[wumLoopIndex] = data;
    //
    //
    //    wumLoopIndex = wumLoopIndex + 1;
    //}
    //
    //wumDB.close();
    system:println(allReleases);
    return allReleases;
}
function getReleasesByProductArea1 (string productArea, int startFormat, int endFormat) (json) {

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

function getAllReleases(int startFormat, int endFormat)(json){


    sql:ClientConnector wumDB = createDBConnection();

    sql:Parameter[] params = [];
    sql:Parameter[] params1 = [];


    sql:Parameter startTimeStamp = {sqlType:"varchar", value:startFormat};
    sql:Parameter endTimeStamp = {sqlType:"varchar", value:endFormat};

    params1=[startTimeStamp,endTimeStamp];


    datatable dtWUMReleaseDetails = wumDB.select("SELECT  update_no AS updateNo, kernel_version AS kernalVersion, platform_version AS platformVersion, date(from_unixtime(floor(timestamp/1000))) AS releaseDate, product_name AS productName, product_version AS productVersion, description AS description, applies_to AS appliesTo, bug_fixes AS bugFixesJson FROM updates where timestamp >= ?  AND timestamp <= ? order by date(from_unixtime(floor(timestamp/1000))), product_name, product_version  ;", params1);
    var wumReleaseDetailsJson, err = <json>dtWUMReleaseDetails;
    logger:info(wumReleaseDetailsJson);
    logger:debug(wumReleaseDetailsJson);
    datatables:close(dtWUMReleaseDetails);
    wumDB.close();

    sql:ClientConnector pqdDB = createPqdDBConnection();
    datatable dtProductAreas = pqdDB.select("SELECT PRODUCT_NAME AS productName, PRODUCT_AREA_NAME AS productArea, PRODUCT_AREA_COLOR AS productColor FROM  WUM_PRODUCT_TO_AREA_MAPPING;", params);
    var productAreasJson, err = <json>dtProductAreas;
    logger:info(productAreasJson);
    logger:debug(productAreasJson);
    datatables:close(dtProductAreas);
    pqdDB.close();
    var productAreasJsonCount = lengthof productAreasJson;


    json allReleases = [];

    string releaseDateMem ="";
    string productNameMem ="";
    string productVersionMem ="";


    var cardId=0;
    var labelDataArrayIndex =0;
    json labelDataArray =[];
    json data ={};
    json labelData ={};

    json details =[];
    var dataRowIndex = 0;


    var labelndex=1;

    var releasesCount=0;

    var detailsIndex=0;
    while(detailsIndex<lengthof wumReleaseDetailsJson){
        json dataRow = {};
        var releaseDate, _ = (string)wumReleaseDetailsJson[detailsIndex].releaseDate;
        var productName, _ = (string)wumReleaseDetailsJson[detailsIndex].productName;
        var productVersion, _ = (string)wumReleaseDetailsJson[detailsIndex].productVersion;

        if(releaseDateMem != releaseDate){



            if(releaseDateMem != ""){


                data.labelDataArray=labelDataArray;
                allReleases[cardId-1]=data;


            }
            releaseDateMem=releaseDate;

            cardId=cardId + 1;

            data={};
            data.id= cardId;
            data.start= releaseDateMem;

            if(productNameMem != "" && productVersionMem != ""){


                labelData.releasesCount = releasesCount;
                labelData.details = details;
                labelDataArray[labelDataArrayIndex]=labelData;
                labelDataArrayIndex = labelDataArrayIndex +1;
            }

            productNameMem ="";
            productVersionMem="";

            labelDataArray =[];
            labelDataArrayIndex=0;



        }




        if(productNameMem != productName || productVersionMem != productVersion){

            if(productNameMem != "" && productVersionMem != ""){


                labelData.releasesCount = releasesCount;
                labelData.details = details;
                labelDataArray[labelDataArrayIndex]=labelData;
                labelDataArrayIndex = labelDataArrayIndex +1;
            }

            releasesCount=1;

            labelData={};
            labelData.id = labelndex;
            labelData.releaseDate = releaseDateMem;
            labelData.productName = productName;
            labelData.productVersion = productVersion;

            var productAreaIndex=0;
            while(productAreaIndex<productAreasJsonCount){
                var productArea_m, _ = (string)productAreasJson[productAreaIndex].productArea;
                var productName_m, _ = (string)productAreasJson[productAreaIndex].productName;
                var productColor_m, _ = (string)productAreasJson[productAreaIndex].productColor;

                if(productName==productName_m){
                    labelData.productArea = productArea_m;
                    labelData.productColor = productColor_m;
                }

                productAreaIndex = productAreaIndex + 1;
            }

            details =[];
            dataRowIndex=0;


            productNameMem = productName;
            productVersionMem = productVersion;

            labelndex = labelndex +1;

        }else{
            releasesCount =releasesCount+1;
        }

        dataRow.id=dataRowIndex +1;
        dataRow.releaseDate=releaseDate;
        dataRow.productName=productName;
        dataRow.productVersion=productVersion;
        dataRow.kernalVersion=wumReleaseDetailsJson[detailsIndex].kernalVersion;
        dataRow.platformVersion=wumReleaseDetailsJson[detailsIndex].platformVersion;
        dataRow.appliesTo=wumReleaseDetailsJson[detailsIndex].appliesTo;
        dataRow.description=wumReleaseDetailsJson[detailsIndex].description;

        var bugFixesString, _=(string )wumReleaseDetailsJson[detailsIndex].bugFixesJson;
        var bugFixesJson=jsons:parse(bugFixesString);

        var key ="-";
        var url ="-";
        var desc ="-";

        if(lengthof bugFixesJson > 0){

            key, _ = (string)bugFixesJson[0].key;
            url, _ = (string)bugFixesJson[0].url;
            desc, _ = (string)bugFixesJson[0].desc;
        }

        dataRow.bugKey = key;
        dataRow.bugUrl = url;
        dataRow.bugDescription = desc;

        details[dataRowIndex]=dataRow;


        dataRowIndex = dataRowIndex +1;





        detailsIndex = detailsIndex +1;
        if(detailsIndex== lengthof wumReleaseDetailsJson){
            if(productNameMem != "" && productVersionMem != ""){


                labelData.releasesCount = releasesCount;
                labelData.details = details;
                labelDataArray[labelDataArrayIndex]=labelData;
                labelDataArrayIndex = labelDataArrayIndex +1;
            }

            data.labelDataArray=labelDataArray;
            allReleases[cardId-1]=data;

        }



    }


    logger:info(allReleases);
    return allReleases;
}
function getReleasesByProductArea(string productArea, int startFormat, int endFormat)(json){

    sql:Parameter[] params3 = [];
    sql:ClientConnector pqdDB = createPqdDBConnection();

    sql:Parameter productAreaName = {sqlType:"varchar", value:productArea};
    params3=[productAreaName];
    datatable dtProductNames = pqdDB.select("SELECT PRODUCT_NAME AS productName, PRODUCT_AREA_COLOR AS productColor FROM  WUM_PRODUCT_TO_AREA_MAPPING Where PRODUCT_AREA_NAME=? ;", params3);
    var productNamesJson, err = <json>dtProductNames;
    logger:debug(productNamesJson);
    datatables:close(dtProductNames);


    logger:info(productNamesJson);

    pqdDB.close();


    string productArray = "\'";


    var productLength =lengthof productNamesJson;
    var productIndex = 0;
    while (productIndex<productLength ){
        var currentProduct, _=(string )productNamesJson[productIndex].productName;
        if(productIndex != (productLength -1)){
            productArray = productArray + currentProduct + "\',\'";
        }else{
            productArray = productArray + currentProduct + "\'";
        }

        productIndex = productIndex +1;
    }


    var productColor, _=(string )productNamesJson[0].productColor;

    logger:info(productArray);


    sql:ClientConnector wumDB = createDBConnection();


    sql:Parameter[] params1 = [];

    sql:Parameter startTimeStamp = {sqlType:"varchar", value:startFormat};
    sql:Parameter endTimeStamp = {sqlType:"varchar", value:endFormat};

    params1=[startTimeStamp,endTimeStamp];

    datatable dtWUMReleaseDetails = wumDB.select("SELECT  update_no AS updateNo, kernel_version AS kernalVersion, platform_version AS platformVersion, date(from_unixtime(floor(timestamp/1000))) AS releaseDate, product_name AS productName, product_version AS productVersion, description AS description, applies_to AS appliesTo, bug_fixes AS bugFixesJson FROM updates where product_name in ("+ productArray +") AND timestamp >= ?  AND timestamp <= ? order by date(from_unixtime(floor(timestamp/1000))), product_name, product_version  ;", params1);
    var wumReleaseDetailsJson, err = <json>dtWUMReleaseDetails;
    logger:info(wumReleaseDetailsJson);
    logger:debug(wumReleaseDetailsJson);
    datatables:close(dtWUMReleaseDetails);

    wumDB.close();

    json allReleases = [];

    string releaseDateMem ="";
    string productNameMem ="";
    string productVersionMem ="";


    var cardId=0;
    var labelDataArrayIndex =0;
    json labelDataArray =[];
    json data ={};
    json labelData ={};

    json details =[];
    var dataRowIndex = 0;


    var labelndex=1;

    var releasesCount=0;

    var detailsIndex=0;
    while(detailsIndex<lengthof wumReleaseDetailsJson){
        json dataRow = {};
        var releaseDate, _ = (string)wumReleaseDetailsJson[detailsIndex].releaseDate;
        var productName, _ = (string)wumReleaseDetailsJson[detailsIndex].productName;
        var productVersion, _ = (string)wumReleaseDetailsJson[detailsIndex].productVersion;

        if(releaseDateMem != releaseDate){



            if(releaseDateMem != ""){


                data.labelDataArray=labelDataArray;
                allReleases[cardId-1]=data;


            }
            releaseDateMem=releaseDate;

            cardId=cardId + 1;

            data={};
            data.id= cardId;
            data.start= releaseDateMem;

            if(productNameMem != "" && productVersionMem != ""){


                labelData.releasesCount = releasesCount;
                labelData.details = details;
                labelDataArray[labelDataArrayIndex]=labelData;
                labelDataArrayIndex = labelDataArrayIndex +1;
            }

            productNameMem ="";
            productVersionMem="";

            labelDataArray =[];
            labelDataArrayIndex=0;



        }




        if(productNameMem != productName || productVersionMem != productVersion){

            if(productNameMem != "" && productVersionMem != ""){


                labelData.releasesCount = releasesCount;
                labelData.details = details;
                labelDataArray[labelDataArrayIndex]=labelData;
                labelDataArrayIndex = labelDataArrayIndex +1;
            }

            releasesCount=1;

            labelData={};
            labelData.id = labelndex;
            labelData.releaseDate = releaseDateMem;
            labelData.productName = productName;
            labelData.productVersion = productVersion;
            labelData.productArea = productArea;
            labelData.productColor = productColor;


            details =[];
            dataRowIndex=0;


            productNameMem = productName;
            productVersionMem = productVersion;

            labelndex = labelndex +1;

        }else{
            releasesCount =releasesCount+1;
        }

        dataRow.id=dataRowIndex +1;

        dataRow.releaseDate=releaseDate;
        dataRow.productName=productName;
        dataRow.productVersion=productVersion;
        dataRow.kernalVersion=wumReleaseDetailsJson[detailsIndex].kernalVersion;
        dataRow.platformVersion=wumReleaseDetailsJson[detailsIndex].platformVersion;
        dataRow.appliesTo=wumReleaseDetailsJson[detailsIndex].appliesTo;
        dataRow.description=wumReleaseDetailsJson[detailsIndex].description;

        var bugFixesString, _=(string )wumReleaseDetailsJson[detailsIndex].bugFixesJson;
        var bugFixesJson=jsons:parse(bugFixesString);

        var key ="-";
        var url ="-";
        var desc ="-";

        if(lengthof bugFixesJson > 0){

            key, _ = (string)bugFixesJson[0].key;
            url, _ = (string)bugFixesJson[0].url;
            desc, _ = (string)bugFixesJson[0].desc;
        }

        dataRow.bugKey = key;
        dataRow.bugUrl = url;
        dataRow.bugDescription = desc;

        details[dataRowIndex]=dataRow;


        dataRowIndex = dataRowIndex +1;





        detailsIndex = detailsIndex +1;
        if(detailsIndex== lengthof wumReleaseDetailsJson){
            if(productNameMem != "" && productVersionMem != ""){

                labelData.releasesCount = releasesCount;
                labelData.details = details;
                labelDataArray[labelDataArrayIndex]=labelData;
                labelDataArrayIndex = labelDataArrayIndex +1;
            }

            data.labelDataArray=labelDataArray;
            allReleases[cardId-1]=data;

        }



    }
    logger:info(allReleases);
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


