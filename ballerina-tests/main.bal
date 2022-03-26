// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
import ballerina/uuid;
import ballerinax/azure_functions as af;

// HTTP request/response with no authentication
@af:Function
public isolated function hello(@af:HTTPTrigger { authLevel: "anonymous" } string payload) 
                      returns @af:HTTPOutput string|error {
    return "Hello, " + payload + "!";
}

// HTTP request to add data to a queue
@af:Function
public isolated function fromHttpToQueue(af:Context ctx, 
            @af:HTTPTrigger {} af:HTTPRequest req, 
            @af:QueueOutput { queueName: "queue1" } af:StringOutputBinding msg) 
            returns @af:HTTPOutput af:HTTPBinding {
    msg.value = req.body;
    return { statusCode: 200, payload: "Request: " + req.toString() };
}

// A message put to a queue is copied to another queue
@af:Function
public isolated function fromQueueToQueue(af:Context ctx, 
        @af:QueueTrigger { queueName: "queue2" } string inMsg,
        @af:QueueOutput { queueName: "queue3" } af:StringOutputBinding outMsg) {
    ctx.log("In Message: " + inMsg);
    ctx.log("Metadata: " + ctx.metadata.toString());
    outMsg.value = inMsg;
}

// // A blob added to a container is copied to a queue
@af:Function
public isolated function fromBlobToQueue(af:Context ctx, 
        @af:BlobTrigger { path: "bpath1/{name}" } byte[] blobIn,
        @af:BindingName { } string name,
        @af:QueueOutput { queueName: "queue3" } af:StringOutputBinding outMsg) 
        returns error? {
    outMsg.value = "Name: " + name + " Content: " + blobIn.toString();
}

// // HTTP request to read a blob value
@af:Function
public isolated function httpTriggerBlobInput(@af:HTTPTrigger { } af:HTTPRequest req, 
                    @af:BlobInput { path: "bpath1/{Query.name}" } byte[]? blobIn)
                    returns @af:HTTPOutput string {
    int length = 0;
    if blobIn is byte[] {
        length = blobIn.length();
    }
    return "Blob: " + req.query["name"].toString() + " Length: " + 
            length.toString() + " Content: " + blobIn.toString();
}

// // HTTP request to add a new blob
@af:Function
public isolated function httpTriggerBlobOutput(@af:HTTPTrigger { } af:HTTPRequest req, 
        @af:BlobOutput { path: "bpath1/{Query.name}" } af:StringOutputBinding bb)
        returns @af:HTTPOutput string|error {
    bb.value = req.body;
    return "Blob: " + req.query["name"].toString() + " Content: " + 
            bb?.value.toString();
}

// // Sending an SMS
@af:Function
public isolated function sendSMS(@af:HTTPTrigger { } af:HTTPRequest req, 
                        @af:TwilioSmsOutput { fromNumber: "+12069845840" } 
                                              af:TwilioSmsOutputBinding tb)
                        returns @af:HTTPOutput string {
    tb.to = req.query["to"].toString();
    tb.body = req.body.toString();
    return "Message - to: " + tb?.to.toString() + " body: " + tb?.body.toString();
}

public type Person record {
    string id;
    string name;
    string country;
};

// // CosmosDB record trigger
@af:Function
public isolated function cosmosDBToQueue1(@af:CosmosDBTrigger { 
        connectionStringSetting: "CosmosDBConnection", databaseName: "db1",
        collectionName: "c1" } Person[] req, 
        @af:QueueOutput { queueName: "queue3" } af:StringOutputBinding outMsg) {
    outMsg.value = req.toString();
}

@af:Function
public isolated function cosmosDBToQueue2(@af:CosmosDBTrigger { 
        connectionStringSetting: "CosmosDBConnection", databaseName: "db1", 
        collectionName: "c2" } json req,
        @af:QueueOutput { queueName: "queue3" } af:StringOutputBinding outMsg) {
    outMsg.value = req.toString();
}

// // HTTP request to read CosmosDB records
@af:Function
public isolated function httpTriggerCosmosDBInput1(
            @af:HTTPTrigger { } af:HTTPRequest httpReq, 
            @af:CosmosDBInput { connectionStringSetting: "CosmosDBConnection", 
                databaseName: "db1", collectionName: "c1", 
                id: "{Query.id}", partitionKey: "{Query.country}" } json dbReq)
                returns @af:HTTPOutput string|error {
    return dbReq.toString();
}

@af:Function
public isolated function httpTriggerCosmosDBInput2(
            @af:HTTPTrigger { } af:HTTPRequest httpReq, 
            @af:CosmosDBInput { connectionStringSetting: "CosmosDBConnection", 
                databaseName: "db1", collectionName: "c1", 
                id: "{Query.id}", partitionKey: "{Query.country}" } Person? dbReq)
                returns @af:HTTPOutput string|error {
    return dbReq.toString();
}

@af:Function
public isolated function httpTriggerCosmosDBInput3(
        @af:HTTPTrigger { route: "c1/{country}" } af:HTTPRequest httpReq, 
        @af:CosmosDBInput { connectionStringSetting: "CosmosDBConnection", 
        databaseName: "db1", collectionName: "c1", 
        sqlQuery: "select * from c1 where c1.country = {country}" } 
        Person[] dbReq)
        returns @af:HTTPOutput string|error {
    return dbReq.toString();
}

// // HTTP request to write records to CosmosDB
@af:Function
public isolated function httpTriggerCosmosDBOutput1(
    @af:HTTPTrigger { } af:HTTPRequest httpReq, @af:HTTPOutput af:HTTPBinding hb) 
    returns @af:CosmosDBOutput { connectionStringSetting: "CosmosDBConnection", 
                                 databaseName: "db1", collectionName: "c1" } json {
    json entry = { id: uuid:createType1AsString(), name: "Saman", country: "Sri Lanka" };
    hb.payload = "Adding entry: " + entry.toString();
    return entry;
}

@af:Function
public isolated function httpTriggerCosmosDBOutput2(
        @af:HTTPTrigger { } af:HTTPRequest httpReq, 
        @af:HTTPOutput af:HTTPBinding hb) 
        returns @af:CosmosDBOutput { 
            connectionStringSetting: "CosmosDBConnection", 
            databaseName: "db1", collectionName: "c1" } json {
    json entry = [{ id: uuid:createType1AsString(), name: "John Doe A", country: "USA" },
                  { id: uuid:createType1AsString(), name: "John Doe B", country: "USA" }];
    hb.payload = "Adding entries: " + entry.toString();
    return entry;
}

@af:Function
public isolated function httpTriggerCosmosDBOutput3(
                    @af:HTTPTrigger { } af:HTTPRequest httpReq) 
                    returns @af:CosmosDBOutput { 
                        connectionStringSetting: "CosmosDBConnection", 
                        databaseName: "db1", collectionName: "c1" } Person[] {
    Person[] persons = [];
    persons.push({id: uuid:createType1AsString(), name: "Jack", country: "UK"});
    persons.push({id: uuid:createType1AsString(), name: "Will", country: "UK"});
    return persons;
}

// // A timer function which is executed every 10 seconds.
@af:Function
public isolated function queuePopulationTimer(
            @af:TimerTrigger { schedule: "*/10 * * * * *" } json triggerInfo, 
            @af:QueueOutput { queueName: "queue4" } af:StringOutputBinding msg) {
    msg.value = triggerInfo.toString();
}
