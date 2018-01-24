package org.wso2.internalapps.pqd;


import ballerina.net.http;
import ballerina.lang.messages;
import ballerina.utils.logger;
import ballerina.lang.system;



@http:configuration {basePath:"/releaseTrainServices",httpsPort: 9096, keyStoreFile: "${ballerina.home}/bre/security/wso2carbon.jks",
                     keyStorePass: "wso2carbon", certPass: "wso2carbon"}
service<http> releaseTrainService {


    @http:GET {}
    @http:Path{value:"/"}
    resource test (message m) {



        test();
        message send={};

        logger:info("test");



        messages:setJsonPayload(send,"test");
        reply send;

    }


    @http:GET {}
    @http:Path{value:"/getAllReleases/{startFormat}/{endFormat}"}
    resource getAllReleases (message m,@http:PathParam {value:"startFormat"} int startFormat,@http:PathParam {value:"endFormat"} int endFormat) {
        message send={};
        system:println(startFormat);
        system:println(endFormat);
        json sendData = getAllReleases(startFormat, endFormat);
        logger:info("/getAllReleases/{startFormat}/{endFormat} Rest call triggered");
        messages:setJsonPayload(send, sendData);
        messages:setHeader(send,"Access-Control-Allow-Origin","*");
        reply send;

    }


    @http:GET {}
    @http:Path{value:"/getProductWiseReleases/{productArea}/{startFormat}/{endFormat}"}
    resource getAllReleasesByProductArea (message m, @http:PathParam {value:"productArea"} string productArea, @http:PathParam {value:"startFormat"} int startFormat, @http:PathParam {value:"endFormat"} int endFormat) {

        message send={};
        json sendData = getReleasesByProductArea(productArea,startFormat, endFormat);
        logger:info("/getProductWiseReleases/{productArea}/{startFormat}/{endFormat} Rest call triggered");
        messages:setJsonPayload(send, sendData);
        messages:setHeader(send,"Access-Control-Allow-Origin","*");
        reply send;

    }

}
