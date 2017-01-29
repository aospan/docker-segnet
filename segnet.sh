#!/bin/bash

rm out/*
./segnet_demo.py --model segnet_sun_low_resolution.prototxt --weights segnet_sun_low_resolution.caffemodel --colours camvid12.png
