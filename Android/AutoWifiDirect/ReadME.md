Mobile Wifi direct peer-to-peer application
================

__Functionality:__
 - Connects to device specified by cloud server automatically
 - Transfers the file specified by the cloud server

__Purpose of files:__

|Filename |Purpose  |New/ Modified|Comments|
|---|---|---|---|
|DeviceDetailFragment.java|       Displaying device details  |  Modified     | Fragment to display details such as the device name and address along with option to connect to it
|DeviceListFragment.java|          Lists available servers	    |    Modified    |  Fragment to display as a list the available devices which could be connected to if required|
|FileTransferService.java     |       Transfer files      |    Modified    |  Performs file transfer using Android’s Wifi  peer-to-peer(P2P)|
|WifiDirectActivity.java  |           Main Activity of  Wifi peer-to-peer  application  |      Modified  |    Provides application view and performs connect and disconnect functions|
|WifiDirectBroadcastReceiver.java  |  Broadcast Receiver     | Modified    |   Used to receive intents broadcast by the Android system|