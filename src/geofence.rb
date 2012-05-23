module Geofence

    MAX_COORD = 180

    # Given an array of coordinat pairs, create a fence estimation and then
    # store that fence within Mongo. Return the Mongo-document that will be
    # stored (containing the estimated ponts and the document id)
    #--
    # Coordinates in format of:
    # [
    #   [:lon, :lat],
    #   [:lon, :lat],
    #   ...
    # ]
    # 
    # ALGORITHM
    # 1. Get the bounding box and generate grid within box
    # 2. Generate the horizontals
    # 3. Foreach horizontal secion of the grid
    #   a. get the intersecting lines
    #   b. for each instersecting line
    #     i. for each grid-block within the horizontal sub-section
    #        1. add the grid-block if the block is to the left of
    #           the intersecting line 
    #        2. else, remove the grid-block from the collection of
    #           included blocks.
    def self.create_fence(coords)


      # get the bounding-box for the polygon (1)
      bounds = get_bounding_box(coords)

      # get the horizontals from the polygon (2)
      horizontals = get_horizontals(coords)

      # split coordinates up into lines (makes life easier)
      lines = coords.zip(coords.dup.rotate(-1))

      # compute the grid (3)
      # TODO rewrite for new horizontal structure
      grid = generate_grid(bounds)
      horizontals.each do |horizontal|
        intersecting_lines(horizontal, lines).each do |line|
          # TODO calculate grid-blocks that are to left of line
          #      and include/remove them into the estimated polygon
        end
      end

      
    end


    # Given the id (document id) of a particular fence and a position (lat,
    # lon), return the poition relative to the fence. This includes two vaules:
    # inside-fence  and  outside-fence
    def self.relative_to_fence(id, pos)
    end


    private
    def self.get_bounding_box(coords)
      # get max and min coords
      max = coords.inject({lat:0, lon:0}) do |max, c|
        max[:lon] = c[0] if c[0] > max[:lon]
        max[:lat] = c[1] if c[1] > max[:lat]
        max
      end
      min = coords.inject({lat:MAX_COORD, lon:MAX_COORD}) do |min, c|
        min[:lon] = c[0] if c[0] < min[:lon]
        min[:lat] = c[1] if c[1] < min[:lat]
        min
      end
      # add a little padding to the max and min
      max.each {|k, v| max[k] += 1 }
      min.each {|k, v| min[k] -= 1 }

      {min: min, max: max}
    end


    # The lines represent lines on the polygons. For example, a triangle
    # of points: [a, b, c] would have lines of:
    #   (a,b) (b,c) (c,a)
    # 
    # Lines in format of:
    # [
    #   [<coordN>, <coord1>],
    #   [<coord1>, <coord2>],
    #   ..., 
    #   [<coordN-1>, <coordN>]
    # ]
    def self.get_horizontals(coords)
      #get all individual horizontals
      h1 = coords.inject([]) do |arr, (lon, lat)|
        arr << lat unless arr.include? lat
        arr
      end

      #wrap those individuals up into cyclic pairs
      h2 = h1.dup
      h1.pop
      h2.shift
      h1.zip(h2)
    end


    # We need to create a conceptual grid in which to do our estimation
    # against. We're actually going to represent our grid-blocks by their
    # centerpoint. Ex:
    # 
    #  _______
    # |       |
    # |   +   |  -- Box and center-point
    # |_______|
    # 
    # We're representing our blocks as points because that's how we're
    # going store and index our fence in Mongo when it's all said and
    # done.
    # 
    # Note: In real-life, we might want to adjust the size of the grid-block
    #       based on how large the geofence is, how granular your estimation
    #       will be, etc. For this example, we're going to use a fixed size
    #       grid block of 0.5x0.5
    def self.generate_grid(bounds)
      lon_range = bounds[:min][:lon]...bounds[:max][:lon]
      lat_range = bounds[:min][:lat]...bounds[:max][:lat]

      grid = []
      lon_range.each do |lon|
        lat_range.each do |lat|
          grid << [lon + 0.25, lat + 0.25]
          grid << [lon + 0.25, lat + 0.75]
          grid << [lon + 0.75, lat + 0.25]
          grid << [lon + 0.75, lat + 0.75]
        end
      end

      grid
    end

end
