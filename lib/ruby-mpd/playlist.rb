require "uri"

class MPD
  # An object representing an .m3u playlist stored by MPD.
  #
  # Playlists are stored inside the configured playlist directory. They are
  # addressed with their file name (without the directory and without the
  # .m3u suffix).
  #
  # Some of the commands described in this section can be used to run playlist
  # plugins instead of the hard-coded simple m3u parser. They can access
  # playlists in the music directory (relative path including the suffix) or
  # remote playlists (absolute URI with a supported scheme).
  class Playlist

    attr_accessor :name

    def initialize(mpd, options)
      @name = options.is_a?(Hash) ? options[:playlist].to_s : options.to_s # convert to_s in case the parser converted to int
      @mpd = mpd
      #@last_modified = options[:'last-modified']
    end

    # Lists the songs in the playlist. Playlist plugins are supported.
    # @return [Array<MPD::Song>] songs in the playlist.
    def songs
      result = @mpd.send_command(:listplaylistinfo, @name)
      # very very dirty hack
      # if in playlist only one stream for example http://like.ru mpd return array ["http:test.ru"] 
      if  result.size==1 && result[0].class != Hash
        result[0] = {:file => result[0]}
      end

      result.map do |hash|
        if hash[:file] && !hash[:file].match(/^(https?:\/\/)?/)[0].empty?
          Song.new(@mpd, {:file => hash[:file], :time => [0]})
        else
          Song.new(@mpd, hash)
        end
      end
    rescue TypeError
      puts "Files inside Playlist '#{@name}' do not exist!"
      return []
    rescue NotFound
      return [] # we rescue in the case the playlist doesn't exist.
    end

    # Loads the playlist into the current queue. Playlist plugins are supported.
    #
    # Since 0.17, a range can be passed to load, to load only a part of the playlist.
    # @macro returnraise
    def load(range=nil)
      @mpd.send_command :load, @name, range
    end

    # Adds URI to the playlist.
    # @macro returnraise
    def add(uri)
      @mpd.send_command :playlistadd, @name, uri
    end

    # Searches for any song that contains +what+ in the +type+ field
    # and immediately adds them to the playlist.
    # Searches are *NOT* case sensitive.
    #
    # @param [Symbol] type Can be any tag supported by MPD, or one of the two special
    #   parameters: +:file+ to search by full path (relative to database root),
    #   and +:any+ to match against all available tags.
    # @macro returnraise
    def searchadd(type, what)
      @mpd.send_command :searchaddpl, @name, type, what
    end

    # Clears the playlist.
    # @macro returnraise
    def clear
      @mpd.send_command :playlistclear, @name
    end

    # Deletes song at position POS from the playlist.
    # @macro returnraise
    def delete(pos)
      @mpd.send_command :playlistdelete, @name, pos
    end

    # Moves song with SONGID in the playlist to the position SONGPOS.
    # @macro returnraise
    def move(songid, songpos)
      @mpd.send_command :playlistmove, @name, songid, songpos
    end

    # Renames the playlist to +new_name+.
    # @macro returnraise
    def rename(new_name)
      @mpd.send_command :rename, @name, new_name
      @name = new_name
    end

    # Deletes the playlist from the disk.
    # @macro returnraise
    def destroy
      @mpd.send_command :rm, @name
    end

  end
end
