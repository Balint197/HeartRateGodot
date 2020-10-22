extends Node

var gameType = "rest"
var tasksdone = 0

# values for rating stress
var restHR = 0
var minHR = 99999
var maxHR = 0
var restRMSSD = 0
var minRMSSD = 99999
var maxRMSSD = 0
var restSDNN = 0 # after rest measure
var minSDNN = 99999 # simple game lowest
var maxSDNN = 0 # simple game highest
var restPNN50 = 0
var minPNN50 = 99999
var maxPNN50 = 0
var restPNN20 = 0
var minPNN20 = 99999
var maxPNN20 = 0
var restSI = 0
var minSI = 99999
var maxSI = 0

var easy_game_level = 0
