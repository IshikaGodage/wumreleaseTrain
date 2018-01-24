package org.wso2.internalapps.pqd;




const string GET_ALL_REDMINE_RELEASE_DATES = "SELECT distinct date(from_unixtime(floor(timestamp/1000))) AS releaseDate FROM updates where timestamp >= ? AND timestamp <= ? ";
const string GET_REDMINE_RELEASE_DETAILS = "SELECT date(from_unixtime(floor(timestamp/1000))) AS releaseDate, product_name AS productName, product_version AS productVersion, count(product_version) AS productVersionCount  FROM updatesdb_200_wso2um.updates where  date(from_unixtime(floor(timestamp/1000)))=? group by product_version;";



const string GET_ALL_REDMINE_RELEASE_DATES_BY_PRODUCT_AREA="SELECT distinct date(from_unixtime(floor(timestamp/1000))) AS releaseDate FROM updates where  product_name in ('wso2am','wso2am-analytics') AND timestamp >= ? AND timestamp <= ? ";
const string GET_REDMINE_RELEASE_DETAILS_BY_PRODUCT_AREA = "SELECT kernel_version AS kernalVersion, platform_version AS platformVersion, product_name AS productName, product_version AS productVersion, description AS description, applies_to AS appliesTo, bug_fixes AS bugFixesJson  FROM updates where product_name in (?) AND date(from_unixtime(floor(timestamp/1000)))=?;";

const string lGET_ALL_REDMINE_RELEASE_DATES_BY_PRODUCT_AREA = "SELECT a.VERSION_DUE_DATE AS releaseDate FROM RM_VERSION AS a LEFT JOIN  RM_MAPPING AS c ON a.PARENT_PROJECT_ID=c.PROJECT_ID WHERE a.VERSION_DUE_DATE !=? AND c.PRODUCT_AREA=? AND VERSION_DUE_DATE > current_date() AND VERSION_DUE_DATE  GROUP BY VERSION_DUE_DATE ASC;";
const string lGET_REDMINE_RELEASE_DETAILS_BY_PRODUCT_AREA = "SELECT a.VERSION_ID AS versionId,c.PROJECT_ID AS projectId,c.PROJECT_NAME AS releaseProduct,c.PRODUCT_AREA AS productArea,a.VERSION_NAME AS releaseVersion,d.USER_FIRST_NAME AS releaseManagerF,d.USER_LAST_NAME AS releaseManagerL,e.USER_FIRST_NAME AS warrantyManagerF,e.USER_LAST_NAME AS warrantyManagerL,a.VERSION_DUE_DATE AS start from RM_VERSION AS a LEFT JOIN  RM_MAPPING AS c ON a.PARENT_PROJECT_ID=c.PROJECT_ID LEFT JOIN RM_USER AS d ON a.VERSION_RELEASE_MANAGER=d.USER_ID LEFT JOIN RM_USER AS e ON a.VERSION_WARRANTY_MANAGER=e.USER_ID WHERE a.VERSION_DUE_DATE=? AND c.PRODUCT_AREA=?;";



