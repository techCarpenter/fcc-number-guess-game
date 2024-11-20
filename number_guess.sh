#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -tq --no-align -c"

declare -i games_played
declare -i best_game
games_played=0
best_game=0
new_player=1

# Prompt for username
echo "Enter your username:"
read username

# Check if user exists
USER_ID=$($PSQL "SELECT player_id FROM players WHERE username = '$username';")

if [[ -z $USER_ID ]]; then
  # Insert new user
  # USER_ID=$($PSQL "INSERT INTO players (username) VALUES ('$username') RETURNING player_id;")
  echo "Welcome, $username! It looks like this is your first time here."
else
  # Welcome existing user
  new_player=0
  games_played=$($PSQL "SELECT games_played from players WHERE username = '$username';")
  best_game=$($PSQL "SELECT best_game_guesses FROM players WHERE username = '$username';")
  echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
fi

# Create new game in db
secret_number=$($PSQL "SELECT CAST(RANDOM()*(1000-1)+1 AS INT);")
echo "SECRET: $secret_number"

# prompt for guess
# declare -i GUESS
declare -i GUESSES
GUESS=-1
GUESSES=0
echo "Guess the secret number between 1 and 1000:"

# loop to play game

re='^[0-9]+$'
while ! [[ $GUESS -eq $secret_number ]]; do
  read GUESS
  if ! [[ $GUESS =~ $re ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi
  
  # track guesses for this game
  GUESSES+=1

  if [[ $GUESS -gt $secret_number ]]; then
    echo "It's lower than that, guess again:"
  elif [[ $GUESS -lt $secret_number ]]; then
    echo "It's higher than that, guess again:"
  elif [[ $GUESS -eq $secret_number ]]; then
    games_played+=1
    echo "You guessed it in $GUESSES tries. The secret number was $secret_number. Nice job!"
    
    if [[ $new_player -eq 1 ]]; then
      $PSQL "INSERT INTO players (username, best_game_guesses, games_played) VALUES ('$username', $GUESSES, $games_played);"
    else
      if [[ $GUESSES -lt $best_game ]]; then
      $PSQL "UPDATE players SET best_game_guesses = $GUESSES, games_played = $games_played WHERE username = '$username';"
      fi
    fi
  fi
done
