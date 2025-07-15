class FishCatchesController < ApplicationController
  before_action :require_signin
  before_action :set_fish_catch, only: %i[show edit update destroy]

  def index
    @pagy, @fish_catches =
      pagy(current_user.filter_catches(params),
           items: params[:per_page] ||= 5,
           link_extra: 'data-turbo-action="advance"')

    @bait_names = Bait.pluck(:name)
    @species = FishCatch::SPECIES
  end

  def show
  end

  def edit
    respond_to do |format|
      format.html { render :edit }
      format.turbo_stream { render :edit }
    end
  end

  def update
    if @fish_catch.update(fish_catch_params)
      dual_flash(:notice, "Catch successfully updated")

      respond_to do |format|
        format.turbo_stream do
          @fish_catches = fish_catches_for_bait(@fish_catch.bait)
          render :update
        end
        format.html { redirect_to tackle_box_item_for_catch(@fish_catch) }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @fish_catch = current_user.fish_catches.new(fish_catch_params)

    if @fish_catch.save
      dual_flash(:notice, "Catch successfully created.")

      respond_to do |format|
        format.turbo_stream do
          @fish_catches = fish_catches_for_bait(@fish_catch.bait)
          @new_catch = current_user.fish_catches.new(bait: @fish_catch.bait)
          render :create
        end
        format.html { redirect_to tackle_box_item_for_catch(@fish_catch) }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @fish_catch.destroy

    dual_flash(:notice, "Catch successfully deleted.")

    respond_to do |format|
      format.turbo_stream do
        @fish_catches = fish_catches_for_bait(@fish_catch.bait)
        render :destroy
      end

      format.html do
        redirect_to tackle_box_item_for_catch(@fish_catch)
      end
    end
  end

private
  def dual_flash(key, message)
    respond_to do |format|
      format.turbo_stream { flash.now[key] = message }
      format.html { flash[key] = message }
    end
  end

  def set_fish_catch
    @fish_catch = current_user.fish_catches.find(params[:id])
  end

  def fish_catch_params
    params.require(:fish_catch).permit(:species, :weight, :length, :bait_id)
  end

  def tackle_box_item_for_catch(fish_catch)
    current_user.tackle_box_items.find_sole_by(bait: fish_catch.bait)
  end

  def fish_catches_for_bait(bait)
    current_user.fish_catches.where(bait: bait).select(:weight)
  end
end
