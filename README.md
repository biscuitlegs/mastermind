# Mastermind

## About:
This is a version of the game Mastermind made in *Ruby(2.6.3)* that is played from the command line.

## How to play:
* CD to the location of *mastermind.rb* on your machine.
* Run the file with: `ruby mastermind.rb`.

## Rules:
###### Playing as Codemaker:
* You will be asked to choose a code consisting of **four colors**.
* You can choose from **red, yellow, green, blue, black and white**.
* You may use **any number of each color** in your four-color code.
* The Computer will try to guess your code each turn.
* If the Computer guesses your code, you lose. If 12 turns pass without the Computer guessing your code, you win.

###### Playing as Codebreaker:
* The Computer will create a code from the colors **red, yellow, green, blue, black and white**. The four-color code can include **any number of any color**.
* Your job is to guess the Computer's code. Each turn, you will be asked to guess the code.
* The Computer will give you feedback about your guess, in the form of **four keypegs**. Each of these keypegs can be either **red or white**.
* A red keypeg indicates that in your guess, one of the colors was the **correct color in the correct position** in the Computer's code -- a perfect match.
* A white keypeg indicates that **a color in your guess was in the code, but in the wrong position**.
* The keypegs aren't given in any particular order, so you will have to deduce which colors are where in the code, and adjust your next guess accordingly.
* If you guess the Computer's code, you win.
* If 12 turns pass and you have not guessed the Computer's code, you lose.