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
SHOT_SPEED = 42
SHOT_COOLDOWN_FRAMES = 4

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

    def sprite_x
        @sprite.x
    end

    def hit_by?(shot)
        @y_level == shot.level &&
            shot.right >= @sprite.x + WIDTH * 0.25 &&
            shot.left <= @sprite.x + WIDTH * 0.75
    end

    def remove
        @sprite.remove
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


class Shot
    attr_reader :level, :left, :right, :direction

    def initialize(player, direction)
        @level = player.z
        @direction = direction
        # Muzzle coordinates relative to the 80px shooting sprite, mirrored when facing left.
        muzzle_x = player.x + player.width * (direction == 1 ? 0.72 : 0.28)
        muzzle_y = player.y + player.height * 0.33
        shot_width = 14
        shot_height = 4
        @shape = Rectangle.new(x: muzzle_x - (direction == -1 ? shot_width : 0),
            y: muzzle_y - shot_height / 2.0, width: shot_width, height: shot_height,
            color: 'yellow', z: @level + 10)
        @left = @shape.x
        @right = @shape.x + @shape.width
    end

    def move
        previous = @shape.x
        @shape.x += SHOT_SPEED * @direction
        @left = [previous, @shape.x].min
        @right = [previous, @shape.x].max + @shape.width
    end

    def outside?
        @shape.x > Window.width || @shape.x + @shape.width < 0
    end

    def remove
        @shape.remove
    end
end

class GameScreen
    attr_writer :zombies

    def initialize()
        @shots = []
        @last_shot_frame = -SHOT_COOLDOWN_FRAMES
        y_level=-1
        @zombies = Array.new(4).map do 
            Zombie.new(y_level+1, Window.width-(rand(100..300)), y_level+=1)
        end 
    end

    def shoot(player, direction)
        return if Window.frames - @last_shot_frame < SHOT_COOLDOWN_FRAMES

        @shots << Shot.new(player, direction)
        @last_shot_frame = Window.frames
    end

    def update
        if Window.frames % 2 == 0
            @zombies.each do |zombie| 
                zombie.move 
                zombie.animate
            end
        end

        @shots.delete_if do |shot|
            shot.move
            targets = @zombies.select { |zombie| zombie.hit_by?(shot) }
            target = targets.min_by { |zombie| shot.direction == 1 ? zombie.sprite_x : -zombie.sprite_x }
            if target
                target.remove
                @zombies.delete(target)
            end
            finished = target || shot.outside?
            shot.remove if finished
            !!finished
        end
    end
end

current_screen = GameScreen.new()
facing = 1

update do
    current_screen.update
end

on :key_held do |event|
    case event.key
    when 'left'
        facing = -1
        atlas.play animation: :walk, flip: :horizontal
        if atlas.x > 0
            atlas.x -= WALK_SPEED
        else
            if background.x < 0
                background.x += WALK_SPEED
            end
        end
    when 'right'
        facing = 1
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
        atlas.play animation: :shoot, flip: (facing == -1 ? :horizontal : nil)
        current_screen.shoot(atlas, facing)
    when 'z'
        atlas.play animation: :die, loop: false
    end      
end

on :key_up do
    atlas.play animation: :idle, loop: true, flip: (facing == -1 ? :horizontal : nil)
end

show