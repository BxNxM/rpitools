#!/bin/bash

thread_name="[t]hread_"*
ps -eT | grep "$thread_name"
