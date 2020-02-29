// Copyright 2020 Adam Shannon
// Use of this source code is governed by an Apache License
// license that can be found in the LICENSE file.

package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	defaultInterval, _ = time.ParseDuration("1m")

	flagAddress  = flag.String("address", "0.0.0.0:10000", "HTTP listen address")
	flagInterval = flag.Duration("interval", defaultInterval, "Interval to check metrics at")
	flagVersion  = flag.Bool("version", false, "Print the iex_exporter version")

	flagLokiAddress = flag.String("loki.address", "", "HTTP address for Loki")

	flagApps = flag.String("apps", "", "Comma separated list of app names to search loki for")
)

func main() {
	flag.Parse()

	if *flagVersion {
		fmt.Println(Version)
		os.Exit(1)
	}

	log.Printf("starting gofuzz_exporter %s", Version)

	ctx, cancelFunc := context.WithCancel(context.Background())
	defer cancelFunc()

	// Listen for application termination.
	errs := make(chan error)
	go func() {
		c := make(chan os.Signal, 1)
		signal.Notify(c, syscall.SIGINT, syscall.SIGTERM)
		errs <- fmt.Errorf("%s", <-c)
	}()

	// Grab fuzz stats on
	cfg := &Config{
		Interval: *flagInterval,
		Apps:     strings.Split(*flagApps, ","),
		Loki: LokiConfig{
			Address: *flagLokiAddress,
		},
	}
	go grabFuzzLogs(ctx, cfg)

	// Start Prometheus metrics endpoint
	h := promhttp.HandlerFor(prometheus.DefaultGatherer, promhttp.HandlerOpts{})
	http.Handle("/metrics", h)

	go func() {
		log.Printf("listenting on %s", *flagAddress)
		if err := http.ListenAndServe(*flagAddress, nil); err != nil {
			log.Printf("ERROR binding to %s: %v", *flagAddress, err)
			errs <- err
		}
	}()

	if err := <-errs; err != nil {
		log.Printf("shutdown error: %v", err)
	}
}
