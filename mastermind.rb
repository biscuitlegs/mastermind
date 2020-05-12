#!/usr/bin/ruby
require 'pry'

module Validation
    def valid?(guess_or_code)
        color = /(red|blue|green|yellow|black|white)/
        return false if !guess_or_code.match(/\w+ \w+ \w+ \w+/)
        return false if guess_or_code.split.length > 4
        return false if !guess_or_code.split.all? {|item| item.match(color)}
        
        true
    end
end

class Peg
    attr_accessor :color

    def initialize(color="")
        @color = color
    end
end

class Board
    attr_reader :codepegs, :keypegs

    def initialize
        @codepegs = Array.new(12) {Array.new(4) {Peg.new} }
        @keypegs = Array.new(12) {Array.new(4) {Peg.new} }
    end

    def get_codepeg(y, x)
        @codepegs[y][x]
    end

    def get_keypeg(y, x)
        @keypegs[y][x]
    end

    def set_color(y, x, color, type)
        if type == "codepeg"
        get_codepeg(y, x).color = color
        elsif type == "keypeg"
        get_keypeg(y, x).color = color
        end
    end

    def win?
        @keypegs.each {|set| return true if set.all? {|peg| peg.color == "red"}}
        
        false
    end
    
end

class Player
    include Validation
    
    attr_reader :name, :role, :code

    def initialize(name="John", role="codebreaker", code="")
        @name = name
        @role = role
        @code = code
    end

    def choose_name
        puts "Player, please enter your name:\n"
        @name = gets.chomp
    end

    def choose_role
        puts "Player, please choose your role:\n"
        role = gets.chomp

        while !valid_role?(role)
            role_error
            role = gets.chomp
        end

        @role = role
    end

    def choose_code
        puts "\n#{self.name}, please create a code:\n"
        code = gets.chomp

        while !valid?(code)
            code_error
            code = gets.chomp
        end

        @code = code.split
    end


    private

    def valid_role?(role)
        role.match(/(codemaker|codebreaker)/) ? true : false
    end

    def role_error
        puts "\nYou can play as the Codemaker or Codebreaker.\n"
        puts "Please enter your desired role again:"
    end

    def code_error
        puts "\nYour code should be in the format:\ncolor color color color\n\n"
        puts "Please enter your code again:"
    end
end

class Computer
    attr_reader :code, :role, :guess

    def initialize(role="codemaker", code=random_code, guess=random_code)
        @role = role
        @code = code
        @guess = guess
    end

    def set_code
        @code = random_code
    end

    def feedback(guess)
        guess_to_keypegs(guess).shuffle
    end

    def set_role(player)
        player.role == "codebreaker" ? @role = "codemaker" : @role = "codebreaker"
        set_code_message
    end

    def guess_code(code)
        @guess.each_with_index do |color, index|
            if get_matches(code, @guess)[index]
                next
            else
                @guess[index] = random_color
            end
        end

        @guess
    end


    private

    def guess_to_keypegs(guess, keypegs=Array.new)
        guess.each_with_index do |peg, i|
            if guess[i] == @code[i]
                keypegs.push(Peg.new("red"))
            elsif guess[i] != @code[i] && @code.include?(guess[i])
                keypegs.push(Peg.new("white"))
            end
        end

        keypegs
    end

    def random_code
        colors = ["black", "white", "blue", "red", "yellow", "green"]
        Array.new(4) {colors.sample}
    end

    def random_color
        colors = ["black", "white", "blue", "red", "yellow", "green"]
        colors.sample
    end

    def set_code_message
        puts "\nThe computer has set the code.\n"
    end

    def get_matches(code, guess)
        matches = []

        code.each_with_index do |color, index|
            matches.push(code[index] === guess[index] ? true : false)
        end

        matches
    end
end

class Game
    include Validation
    attr_reader :player, :computer, :turn

    def initialize(player, computer, board=Board.new, turn=0)
        @board = board
        @player = player
        @computer = computer
        @turn = turn
    end

    def play
        @player.role == "codebreaker" ? play_as_codebreaker : play_as_codemaker
        game_over_message
    end


    private

    def play_as_codemaker
        player.choose_code
        
        while true
            puts "\nThe Computer is thinking...\n"
            sleep 2
            guess = @computer.guess_code(@player.code)
            puts "\nThe Computer has guessed #{guess.join(" ")}.\n"

            if computer_correct_guess?
                codemaker_loss_message
                return
            end

            if @turn > 10
                codemaker_winner_message
                return
            end

            @turn += 1
        end
    end

    def play_as_codebreaker
        while true
            puts "\n#{self.player.name}, please guess the code:\n"
            guess = gets.chomp
            
            while !valid?(guess)
                guess_error
                guess = gets.chomp
            end

            guess = guess.split
            guess.each_with_index do |color, index|
                @board.set_color(@turn, index, color, "codepeg")
            end

            feedback = @computer.feedback(guess)
            puts "\nThe Computer has placed #{feedback.length} keypeg(s):"
            feedback.each_with_index do |peg, index| 
                @board.set_color(@turn, index, peg.color, "keypeg")
                puts peg.color
            end

            if @board.win?
                codebreaker_winner_message
                return
            end

            if @turn > 10
                codebreaker_loss_message
                return
            end

            @turn += 1
        end
    end

    def computer_correct_guess?
        @computer.guess == @player.code ? true : false
    end

    def guess_error
        puts "\nYour guess should be in the format:\ncolor color color color\n\n"
        puts "Please enter your guess again:"
    end

    def codebreaker_loss_message
        puts "\nSorry #{@player.name}, you didn't break the code this time!"
        puts "The code was: #{@computer.code}."
    end

    def codebreaker_winner_message
        puts "\nCongrats #{@player.name}! You guessed the code!"
    end

    def codemaker_loss_message
        puts "\nSorry, #{@player.name}, but the Computer guessed your code!"
    end

    def codemaker_winner_message
        puts "\nNice one #{@player.name}, the Computer didn't crack your code!"
    end

    def game_over_message
        puts "\nGame Over! Thanks for playing!"
    end
end

def new_game
    player = Player.new
    player.choose_name
    player.choose_role
    
    computer = Computer.new
    computer.set_role(player)
    
    Game.new(player, computer)
end


game = new_game
game.play