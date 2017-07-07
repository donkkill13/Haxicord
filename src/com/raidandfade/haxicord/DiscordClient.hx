package com.raidandfade.haxicord;

import com.raidandfade.haxicord.websocket.WebSocketConnection;
import com.raidandfade.haxicord.endpoints.Endpoints;

import haxe.Json;
import haxe.Timer;

class DiscordClient { 
    public static var libName:String = "Haxicord";
    public static var userAgent:String = "DiscordBot (https://github.com/RaidAndFade/Haxicord, 0.0.1)";
    public static var gatewayVersion:Int = 6;

    public var token:String;
    public var isBot:Bool;

    public var endpoints:Endpoints;

    var hbThread:HeartbeatThread;
    var ws:WebSocketConnection;

    public function new(_tkn:String){ //Sharding? lol good joke.
        token = _tkn; //ASSUME BOT FOR NOW. Deal with users later maybe.
        isBot = true;
        
        endpoints = new Endpoints(this);

        trace("Getting gotten");
        endpoints.getGateway(false,connect);
        //Init websocket
		//ws = new WebSocketConnection("ws://echo.websocket.org");
		//ws.send("Henlo!");
    }
//Flowchart
    public function connect(gateway){
        trace("Gottening");
        ws = new WebSocketConnection(gateway.url+"?v="+gatewayVersion+"&encoding=json");
        ws.onMessage = webSocketMessage;
        ws.onClose = function(){
            if(hbThread!=null)hbThread.pause();
            trace("Rip'd");
        }
        ws.onError = function(e){
            if(hbThread!=null)hbThread.pause();

        }
    }

    public function webSocketMessage(msg){
        var m:WSMessage = Json.parse(msg);
        var d:Dynamic;
        d = m.d;
        trace(m);
        switch(m.op){
            case 10: 
                ws.sendJson(WSPrepareData.Identify(token));
                hbThread = new HeartbeatThread(d.heartbeat_interval,ws,null);
            default:
        }
    }

    public function start(blocking=true){
#if sys
        while(blocking){
            Sys.sleep(1);
        }
#end
    }
//Events 
    public dynamic function onWSOpen(){
        
    }

    public dynamic function onOpen(){

    }

}

typedef WSMessage = {
    var op:Int;
    var d:Dynamic;
    var s:Int;
    var t:String;
}

class WSPrepareData {
    public static function Identify(t:String, p:WSIdentify_Properties=null, c:Bool=false, l:Int=59, s:WSShard=null){
        if(p==null) p = {"$os":"","$browser":DiscordClient.libName,"$device":DiscordClient.libName,"$referrer":"","$referring_domain":""};
        if(s==null) s = [0,1];
        return {"op":2,"d":{"token":t,"properties":p,"compress":c,"large_threshhold":l,"shard":s}};
    }

    public static function Heartbeat(seq=null){
        return {"op":1,"d":seq};
    }
}

typedef WSShard = Array<Int>;

typedef WSIdentify_Properties = {
    @:optional var os:String;
    @:optional var browser:String;
    @:optional var device:String;
    @:optional var referrer:String;
    @:optional var referring_domain:String;
}

class HeartbeatThread { 
    public var delay:Int;

    var seq:Int;
    var ws:WebSocketConnection;
    var timer:Timer;

    public function setSeq(_s){
        seq = _s;
    }

    public function new(_d,_w,_s){
        delay = _d;
        ws=_w;
        seq=_s;
        timer = new Timer(delay);
        timer.run = beat;
    }

    public function beat(){
        ws.sendJson(WSPrepareData.Heartbeat(seq));
    }

    public function pause(){
        timer.stop();
    }

    public function resume(){
        timer = new Timer(delay);
        beat();
        timer.run = beat;
    }
}