module Review
  class Diff
    attr_reader :files

    def initialize(text)
      lines = text.split("\n")
      @files = Parser.new(lines, 'diff --git', File).parse
    end
  end

  class File
    attr_reader :created
    attr_reader :hunks
    attr_reader :name
    attr_reader :original_name
    attr_reader :removed
    attr_reader :renamed

    def initialize(lines)
      header_lines = get_header_lines(lines)
      hunk_lines = lines[header_lines.length..-1]

      @hunks = Parser.new(hunk_lines, '@@', Hunk).parse

      original_name, new_name = nil, nil
      header_lines.each do |line|
        if line.start_with?('---')
          original_name = line[4..-1].chomp
        elsif line.start_with?('+++')
          new_name = line[4..-1].chomp
        end
      end

      @created = original_name == '/dev/null'
      @removed = new_name == '/dev/null'
      @renamed = !@created && !@removed && new_name != original_name

      original_name = nil if @created
      new_name = nil if @removed

      # Note: Names can be nil under special circumstances, such as when
      #       only the mode of a file is changed.
      # TODO: Investigate other potential special cases.
      original_name = original_name[2..-1] if original_name
      new_name = new_name[2..-1] if new_name

      if @created
        @name = new_name
      elsif @removed
        @name = nil
      elsif @renamed
        @name = new_name
      else
        @name = original_name
      end

      @original_name = original_name
    end

    def get_header_lines(lines)
      headers = []
      lines.each do |line|
        break if line.nil? || line.start_with?('@@')
        headers.push(line)
      end
      headers
    end

    # Return all changed lines of all hunks
    def lines
      all_lines = []
      @hunks.each {|h| all_lines.concat(h.lines) }
      all_lines
    end
  end

  # TODO: Detect changed lines
  # TODO: Parse @@ line
  class Hunk
    attr_reader :lines
    attr_reader :added_lines
    attr_reader :removed_lines

    def initialize(lines)
      @lines = []
      @added_lines = []
      @removed_lines = []
      lines.each do |line|
        first_char = line[0]
        if first_char == '+' || first_char == '-'
          line = line[1..-1].chomp
          @lines.push(line)
          if first_char == '+'
            @added_lines.push(line)
          else
            @removed_lines.push(line)
          end
        end
      end
    end
  end

  class Parser
    def initialize(lines, marker, type)
      @lines = lines
      @marker = marker
      @type = type
    end

    def parse
      i = 0
      items = []
      until i == @lines.length
        line = @lines[i]
        if line.start_with?(@marker)
          j = i + 1
          line = @lines[j]
          until line.nil? || line.start_with?(@marker)
            j += 1
            line = @lines[j]
          end
          items.push(@type.new(@lines[i...j]))
          i = j
        end
      end
      items
    end
  end
end
