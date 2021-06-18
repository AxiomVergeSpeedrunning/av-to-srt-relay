package main

import (
	"flag"
	"fmt"
	"github.com/gorilla/websocket"
	"log"
	"net/url"
	"os"
	"os/signal"
	"time"
)

var gameHost = flag.String("game-host", "localhost:19906", "IP address of the computer running Axiom Verge")
var relayHost = flag.String("relay-host", "relay.aricodes.net", "IP address of the relay server to send traffic to")

var username = flag.String("username", "", "Your username")

func GetConnection(u url.URL) *websocket.Conn {
	c, _, err := websocket.DefaultDialer.Dial(u.String(), nil)
	if err != nil {
		log.Fatal("Unable to connect to ", u.String())
	}

	return c
}

func main() {
	flag.Parse()

	if *username == "" {
		fmt.Print("Enter your username: ")
		fmt.Scanf("%s", username)
	}

	// Set up connections
	gameUrl := url.URL{Scheme: "ws", Host: *gameHost, Path: "/"}
	relayUrl := url.URL{Scheme: "wss", Host: *relayHost, Path: "/ws"}

	log.Println("Initializing game connection with host", gameUrl.String())
	gameConn := GetConnection(gameUrl)
	defer gameConn.Close()

	log.Println("Initializing relay connection with host", relayUrl.String())
	relayConn := GetConnection(relayUrl)
	defer relayConn.Close()

	// Set up channels for signal processing
	interrupt := make(chan os.Signal, 1)
	signal.Notify(interrupt, os.Interrupt)

	done := make(chan struct{})

	relayConn.WriteMessage(websocket.TextMessage, []byte(fmt.Sprintf("ident:%s", *username)))

	go func() {
		defer close(done)
		for {
			messageType, message, err := gameConn.ReadMessage()
			if err != nil {
				log.Println("Read error:", err)
				return
			}
			relayConn.WriteMessage(messageType, message)
		}
	}()

	log.Println("Connections made! Bridging messages.")

	for {
		select {
		case <-done:
			return
		case <-interrupt:
			log.Println("Interrupt received, cleaning up connections")

			err := relayConn.WriteMessage(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""))
			if err != nil {
				log.Fatal("Error closing relay connection:", err)
			}

			err = gameConn.WriteMessage(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""))
			if err != nil {
				log.Fatal("Error closing game connection:", err)
			}

			select {
			case <-done:
			case <-time.After(time.Second):
			}

			return
		}
	}
}
