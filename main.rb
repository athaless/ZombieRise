require 'ruby2d'

set title: 'Zombie Rise (by Aless)',
    background: 'black',
    width: 1280,
    height: 600,
    fps_cap: 10

PLAYER_SCALE = 3
ZOMBIE_SCALE = 1.8

PLAYER_CLIP_WIDTH = 80
ZOMBIE_CLIP_WIDTH = 125

WALK_SPEED = 12

Y_LEVELS = [180, 230, 280, 320]
Y_LEVEL_START = 0


background = Image.new('resources/images/BackgroundCitySeamless.png', y:0, height: Window.height + 50)

class Zombie
    WIDTH = ZOMBIE_CLIP_WIDTH * ZOMBIE_SCALE
    HEIGHT = ZOMBIE_CLIP_WIDTH * ZOMBIE_SCALE

    attr_reader :image, :x, :y, :speed

    def initialize(type, x, y_level)
        @x = x
        @y_level = y_level
        @speed = rand(-4.0..-1.0)
        @type = (type < 0 || type > 3)? rand(0..3) : type

        case @type
        when 0 
            @image = 'resources/images/zombie-half-woman.png'
        when 1
            @image = 'resources/images/zombie-old-woman.png'
        when 2
            @image = 'resources/images/zombie-skinny-guy.png'
        when 3
            @image = 'resources/images/zombie-jump-guy.png'
        end

        @sprite = Sprite.new(@image, width: WIDTH, height: HEIGHT, clip_width: ZOMBIE_CLIP_WIDTH,
            x: @x,
            y: Y_LEVELS[@y_level],
            time: 200,
            loop: true,
            z: y_level
        )
    end

    def animate
        @sprite.play(flip: :horizontal, loop: true)
    end

    def move
        @sprite.x = (@sprite.x + @speed) % Window.width
    end
end


atlas = Sprite.new(
    'resources/images/hero_spritesheet-inline2.png',
    width: PLAYER_CLIP_WIDTH * PLAYER_SCALE,
    height: PLAYER_CLIP_WIDTH * PLAYER_SCALE,
    clip_width: PLAYER_CLIP_WIDTH,
    animations: {
        idle: 0..7,
        walk: 8..13,
        shoot: 14..20,
        jump: 21..21,
        die: 23..26,
        crounch: 28..28
      },
    time: 50,
    y: Y_LEVELS[Y_LEVEL_START],  
    z: Y_LEVEL_START
)


class GameScreen
    attr_writer :zombies

    def initialize()
        y_level=-1
        @zombies = Array.new(4).map do 
            Zombie.new(y_level+1, Window.width-(rand(100..300)), y_level+=1)
        end 
    end

    def update
        if Window.frames % 2 == 0
            @zombies.each do |zombie| 
                zombie.move 
                zombie.animate
            end
        end

    end
end

current_screen = GameScreen.new()

update do
    current_screen.update
end

on :key_held do |event|
    case event.key
    when 'left'
        atlas.play animation: :walk, flip: :horizontal
        if atlas.x > 0
            atlas.x -= WALK_SPEED
        else
            if background.x < 0
                background.x += WALK_SPEED
            end
        end
    when 'right'
        atlas.play animation: :walk
       if atlas.x < (Window.width - atlas.width) 
            atlas.x += WALK_SPEED
        else
            if background.x - Window.width >= -background.width
                background.x -= WALK_SPEED
            end
        end
    when 'up'
        if atlas.y > Y_LEVELS.first
            atlas.play animation: :jump
            atlas.y = Y_LEVELS[atlas.z - 1]
            atlas.z -= 1
        end
    when 'down'
        if atlas.y < Y_LEVELS.last
            atlas.play animation: :jump
            atlas.y = Y_LEVELS[atlas.z + 1]
            atlas.z +=  1
        else
            atlas.play animation: :crounch
        end
    when 'space'
        atlas.play animation: :shoot
    when 'z'
        atlas.play animation: :die, loop: false
    end      
end

on :key_up do
    atlas.play animation: :idle, loop: true
end

show