import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import 'dart:io';

// =============================================================
// 🔑 KONFIGURASI SESUAI HIVEMQ CLOUD OVERVIEW
// =============================================================
const String _mqttHost = '4ecff5933a704e218192a9a9390c3580.s1.eu.hivemq.cloud';
const int _mqttPort = 8883; // TLS MQTT port (bukan websocket!)
const String _mqttUsername = 'ayamA';
const String _mqttPassword = 'Al280805.';
// =============================================================

class MqttService {
  late MqttServerClient client;
  
  Function(String topic, String message)? onMessageReceived;

  MqttService() {
    _initializeClient();
  }

  void _initializeClient() {
    final clientId = 'flutter_ayam_${DateTime.now().millisecondsSinceEpoch}';
    
    print('');
    print('🔧 ==========================================');
    print('🔧   MQTT CLIENT INITIALIZATION');
    print('🔧 ==========================================');
    print('   Host: $_mqttHost');
    print('   Port: $_mqttPort (TLS)');
    print('   Username: $_mqttUsername');
    print('   Client ID: $clientId');
    print('');
    
    client = MqttServerClient.withPort(_mqttHost, clientId, _mqttPort);
    
    // ⚠️ CRITICAL: TLS Configuration yang lebih permissive
    client.secure = true;
    
    // Create custom security context
    final context = SecurityContext.defaultContext;
    client.securityContext = context;
    
    // SKIP certificate verification (Android sering bermasalah dengan cert chain)
    client.onBadCertificate = (dynamic cert) {
      print('⚠️ Certificate validation bypassed');
      return true;
    };
    
    // Connection settings
    client.keepAlivePeriod = 20; // Lebih sering keep alive
    client.connectTimeoutPeriod = 5000; // 5 second timeout
    client.autoReconnect = true;
    client.resubscribeOnAutoReconnect = true;
    
    // Disable WebSocket (gunakan native MQTT over TLS)
    client.useWebSocket = false;
    
    // Logging
    client.logging(on: false); // Matikan log verbose
    
    // Protocol
    client.setProtocolV311();
    
    print('✅ Client configured');
  }

  Future<void> connect() async {
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(client.clientIdentifier)
        .authenticateAs(_mqttUsername, _mqttPassword)
        .withWillQos(MqttQos.atMostOnce)
        .startClean() // Clean session
        .keepAliveFor(20);

    client.connectionMessage = connMessage;

    try {
      print('🔌 Attempting MQTT connection...');
      print('   Connecting to: $_mqttHost:$_mqttPort');
      
      await client.connect(_mqttUsername, _mqttPassword);
      
      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        print('');
        print('🎉 ==========================================');
        print('🎉   CONNECTION SUCCESSFUL! ✅');
        print('🎉 ==========================================');
        print('   State: ${client.connectionStatus!.state}');
        print('   Return Code: ${client.connectionStatus!.returnCode}');
        print('');
        
        _setupMessageListener();
      } else {
        print('❌ Connection failed');
        print('   State: ${client.connectionStatus!.state}');
        print('   Return Code: ${client.connectionStatus!.returnCode}');
        
        if (client.connectionStatus!.returnCode == MqttConnectReturnCode.notAuthorized) {
          print('💡 Credentials rejected - check username/password');
        } else if (client.connectionStatus!.returnCode == MqttConnectReturnCode.badUsernameOrPassword) {
          print('💡 Invalid username or password');
        }
        
        client.disconnect();
      }
    } on NoConnectionException catch (e) {
      print('❌ NoConnectionException');
      print('   Error: $e');
      print('');
      print('💡 Possible solutions:');
      print('   1. Check internet connection');
      print('   2. Verify firewall allows port 8883');
      print('   3. Try mobile data instead of WiFi');
      print('   4. Restart the app');
      client.disconnect();
    } on SocketException catch (e) {
      print('❌ SocketException');
      print('   Error: $e');
      print('💡 Network connectivity issue');
      client.disconnect();
    } catch (e) {
      print('❌ Unexpected error: $e');
      client.disconnect();
    }
  }

  void _setupMessageListener() {
    print('🎧 Setting up message listener...');
    
    client.updates!.listen(
      (List<MqttReceivedMessage<MqttMessage>> messages) {
        final recMessage = messages[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);
        final topic = messages[0].topic;
        
        print('');
        print('📬 ═══════════════════════════════════════');
        print('   📨 NEW MESSAGE RECEIVED!');
        print('═══════════════════════════════════════');
        print('   📍 Topic: $topic');
        print('   📦 Data: $payload');
        print('   ⏰ Time: ${DateTime.now().toString().substring(11, 19)}');
        print('═══════════════════════════════════════');
        print('');
        
        if (onMessageReceived != null) {
          print('✅ Calling callback...');
          onMessageReceived!(topic, payload);
        } else {
          print('⚠️ No callback handler registered');
        }
      },
      onError: (error) {
        print('❌ Stream error: $error');
      },
      onDone: () {
        print('⚠️ Stream closed');
      },
      cancelOnError: false,
    );
    
    print('✅ Listener active and monitoring...');
  }

  void subscribe(String topic) {
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('');
      print('📡 Subscribing to topic: $topic');
      client.subscribe(topic, MqttQos.atLeastOnce);
      print('✅ Subscription confirmed');
      print('   Waiting for messages...');
      print('');
    } else {
      print('❌ Cannot subscribe - not connected');
      print('   Current state: ${client.connectionStatus!.state}');
    }
  }

  void unsubscribe(String topic) {
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('🔕 Unsubscribing from: $topic');
      client.unsubscribe(topic);
    }
  }

  void publish(String topic, String message) {
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print('📤 Published to $topic');
    } else {
      print('❌ Cannot publish - not connected');
    }
  }

  void disconnect() {
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      client.disconnect();
      print('🔌 Disconnected');
    }
  }
  
  // Helper: Check connection status
  bool get isConnected => 
      client.connectionStatus?.state == MqttConnectionState.connected;
}

final mqttService = MqttService();