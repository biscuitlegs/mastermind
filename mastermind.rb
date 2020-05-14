#!/usr/bin/ruby
require 'pry'
#make computer set codepegs when it guesses

module Validation
    def valid?(guess_or_code)
        color = /(red|blue|green|yellow|black|white)/
        return false if !guess_or_code.match(/\w+ \w+ \w+ \w+/)
        return false if guess_or_code.split.length > 4
        return false if !guess_or_code.split.all? {|item| item.match(color)}
        
        true
    end
end

module CodeTools
    def random_code
        colors = ["black", "white", "blue", "red", "yellow", "green"]
        Array.new(4) {Peg.new(colors.sample)}
    end

    def random_color
        colors = ["black", "white", "blue", "red", "yellow", "green"]
        colors.sample
    end

    def get_colors(code)
        colors = []
        code.each {|peg| colors.push(peg.color)}

        colors
    end

    def colors_to_codepegs(colors)
        colors.split.map {|color| color = Peg.new(color) }
    end

    def guess_to_keypegs(guess, code, keypegs=Array.new)
        guess.each_with_index do |peg, i|
            if guess[i].color == code[i].color
                keypegs.push(Peg.new("red"))
            elsif guess[i].color != code[i].color && code.any? {|peg| peg.color == guess[i].color}
                keypegs.push(Peg.new("white"))
            end
        end

        keypegs
    end

end

class Peg
    attr_accessor :color, :locked

    def initialize(color="", locked=false)
        @color = color
        @locked = locked
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

    def set_codepegs(guess, turn)
        guess.each_with_index do |peg, index|
            @codepegs[turn][index].color = peg.color
        end
    end

    def set_keypegs(guess, turn)
        guess.each_with_index do |peg, index|
            @keypegs[turn][index].color = peg.color
        end
    end

    def cracked_code?
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
        puts "\n"
    end

    def choose_role
        puts "#{@name}, please choose your role:\n"
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

        @code = code.split.map {|color| color = Peg.new(color) }
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
    include CodeTools

    def initialize(role="codemaker", code=random_code, guess=random_code)
        @role = role
        @code = code
        @guess = guess
    end

    def set_code
        @code = random_code
    end

    def feedback(guess)
        guess_to_keypegs(guess, @code).shuffle
    end

    def set_role(player)
        player.role == "codebreaker" ? @role = "codemaker" : @role = "codebreaker"
    end

    def guess_code(code)
        lock_matching_pegs(code, @guess)
        include_half_matching_pegs(code, @guess)

        @guess
    end


    private

    def get_half_matches(code, guess)
        matches = []
        code.each_with_index do |peg, i|
            if guess[i] != code[i] && get_colors(code).include?(guess[i].color)
                matches.push(guess[i].color)
            end
        end

        matches
    end

    def include_half_matching_pegs(code, guess)
        half_pegs = get_half_matches(code, guess).shuffle

        guess.each do |peg|
            if peg.locked
                next
            else
                peg.color = random_color
            end
        end

        while half_pegs - get_colors(guess) != []
            guess.each do |peg|
                if peg.locked
                    next
                elsif !half_pegs.empty?
                    peg.color = half_pegs[0]
                    half_pegs.shift
                end
            end
        end
    end

    def lock_matching_pegs(code, guess)
        code.each_with_index do |peg, index|
            if code[index].color === guess[index].color
                guess[index].locked = true
            end
        end
    end
end

class Game
    attr_reader :player, :computer, :turn
    include Validation
    include CodeTools

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
        @player.choose_code
        
        while true
            computer_thinking_message

            guess = @computer.guess_code(@player.code)

            while already_guessed_code?(@computer.guess, @board)
                guess = @computer.guess_code(@player.code)
            end 
            
            @board.set_codepegs(@computer.guess, @turn)
            @board.set_keypegs(guess_to_keypegs(@computer.guess, @player.code), @turn)
            computer_guess_message(@computer.guess)

            if @board.cracked_code?
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
        set_code_message

        while true
            puts "\n#{@player.name}, please guess the code:\n"
            guess = gets.chomp
            
            while !valid?(guess)
                guess_error
                guess = gets.chomp
            end

            guess = colors_to_codepegs(guess)
            @board.set_codepegs(guess, @turn)

            feedback = @computer.feedback(guess)
            @board.set_keypegs(feedback, @turn)
            feedback_message(feedback)

            if @board.cracked_code?
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
        @computer.guess.each_with_index do |peg, i|
            return false if @computer.guess[i].color != @player.code[i].color
        end

        true
    end

    def already_guessed_code?(guess, board)
        board.codepegs.each do |set|
            return true if get_colors(guess) == get_colors(set)
        end
        
        return false
    end

    def guess_error
        puts "\nYour guess should be in the format:\ncolor color color color\n\n"
        puts "Please enter your guess again:"
    end

    def codebreaker_loss_message
        puts "\nSorry #{@player.name}, you didn't break the code this time!"
        puts "\nThe code was:"
        @computer.code.each {|codepeg| print "#{codepeg.color} "}
        puts ""
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

    def set_code_message
        puts "\nThe computer has set the code.\n"
    end

    def computer_guess_message(guess)
        puts "\nThe Computer has guessed:\n"
        guess.each {|peg| print "#{peg.color} "}
        puts ""
    end

    def computer_thinking_message
        puts "\nThe Computer is thinking...\n"
        sleep 2
    end

    def feedback_message(feedback)
        puts "\nThe Computer has placed #{feedback.length} keypeg(s):"
        feedback.each {|keypeg| puts keypeg.color}
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