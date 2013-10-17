module Review
  class Section
    @marker = nil
    @subsection_type = nil

    attr_reader :text
    attr_reader :subsections

    class << self
      attr_reader :marker
      attr_reader :subsection_type
    end

    def initialize(text)
      @text = text
      @header_lines = header_lines
      @content_lines = content_lines
      @subsections = subsections
    end

    def header_lines
      lines = []
      type = self.class.subsection_type
      return lines if type.nil?
      marker = type.marker
      @text.each_line do |line|
        break if line.nil? || line.start_with?(marker)
        lines.push(line)
      end
      lines
    end

    def content_lines
      @text.lines.drop(@header_lines.length)
    end

    def subsections
      subsections = []
      type = self.class.subsection_type
      return subsections if type.nil?
      i = 0
      lines = @content_lines
      marker = type.marker
      until i == lines.length
        line = lines[i]
        if line.start_with?(marker)
          j = i + 1
          line = lines[j]
          until line.nil? || line.start_with?(marker)
            j += 1
            line = lines[j]
          end
          text = lines[i...j].join()
          subsection = type.new(text)
          subsections.push(subsection)
          i = j
        end
      end
      subsections
    end
  end

  # TODO: Detect changed lines
  # TODO: Parse @@ line
  class Hunk < Section
    @marker = '@@'

    attr_reader :added_lines
    attr_reader :removed_lines

    def initialize(text)
      super(text)

      @added_lines = []
      @removed_lines = []

      @content_lines.each do |line|
        first_char = line[0]
        if first_char == '+' || first_char == '-'
          line = line[1..-1].chomp
          if first_char == '+'
            @added_lines.push(line)
          else
            @removed_lines.push(line)
          end
        end
      end
    end
  end

  class File < Section
    @marker = 'diff --git'
    @subsection_type = Hunk

    attr_reader :created
    attr_reader :name
    attr_reader :original_name
    attr_reader :removed
    attr_reader :renamed

    alias_method :hunks, :subsections

    def initialize(text)
      super(text)

      original_name, new_name = nil, nil
      @header_lines.each do |line|
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

    # Return all changed lines of all hunks
    def lines
      all_lines = []
      @subsections.each do |h|
        all_lines += h.added_lines + h.removed_lines
      end
      all_lines
    end
  end

  class Diff < Section
    @subsection_type = File
    alias_method :files, :subsections
  end
end
