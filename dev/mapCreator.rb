require 'io/console'

$w = 10
$h = 5

$screen = (" " * $w + "|\n") * $h + ("-" * $w + "|")
$update = true
$y = 0
$x = 0

def resize(x,y)
  if x == -1
    for i in 0 .. $h
      $screen[i * ($w + 1) + $w] = ""
      $screen[i * ($w + 1) + $w - 1] = "|"
    end
    $w -= 1
    $update = true
  elsif x == 1
    $w += 1
    for i in 0 .. $h - 1
      $screen[i * ($w + 2) + $w - 1] = " |"
    end
    $screen[$h * ($w + 2) + $w - 1] = "-|"
    $update = true
  elsif y == -1
    $screen[($h - 1) * ($w + 1) .. $h * ($w + 1)] = ""
    $h -= 1
    $update = true
  elsif y == 1
    $screen[$h * ($w + 2)] = (" " * $w + "|\n-")
    $h += 1
    $update = true
  end
end

def moveLeft()
  if $x - 1 >= 0
    $update = true
    $x -= 1
  elsif $y - 1 >= 0
    $update = true
    $y -= 1
    $x = $w - 1
  end
end

def moveRight()
  if $x + 1 < $w
    $update = true
    $x += 1
  elsif $y + 1 < $h
    $update = true
    $y += 1
    $x = 0
  end
end

def moveDown()
  if $y + 1 < $h
    $update = true
    $y += 1
  end
end

while true
  if $update == true
    $update = false
    system "clear" || cls
    puts $screen
    print "\e[#{$y + 1};#{$x + 1}H"
  end

  input = STDIN.getch
  if input == "\e"
    if STDIN.getch == "["
      case STDIN.getch
      when "A"
        if $y - 1 >= 0
          $y -= 1
          $update = true
        end
      when "B"
        moveDown()
      when "C"
        moveRight()
      when "D"
        moveLeft()
      when "3"
        if STDIN.getch == "~"
          $screen[$y * ($w + 2) + $x] = " "
          $update = true
        end
      end
    end
  elsif input == "\u007f" or input == "\b"
    delete = $y * ($w + 2) + $x - 1 
    if $x == 0
      delete -= 2
    end
    if $x > 0
      $update = true
      $screen[delete] = " "
    end
    moveLeft()
  elsif input == "\u000d"
    moveDown() 
  elsif input == "-"
    resize(-1,0)
  elsif input == "="
    resize(1,0)
  elsif input == "["
    resize(0,-1)
  elsif input == "]"
    resize(0,1)
  elsif input == "Q"
    break
  elsif input == ";"
    STDIN.getch
    STDIN.getch
  else
    $screen[$y * ($w + 2) + $x] = input
    $update = true
    moveRight()
  end
  exit if input=="\u0018" or input=="\u0003"
end

system "clear" || cls
$screen[$h * ($w + 2) .. $h * ($w + 2) + $w] = ""
for i in 0 .. $h - 1
  $screen[i * ($w + 1) + $w] = ""
end
File.write('map', $screen)
