class TackleBoxItemsController < ApplicationController
  before_action :require_signin

  def index
    if item = current_user.tackle_box_item_for_most_recent_catch
      redirect_to action: :show, id: item
    else
      render :empty
    end
  end

  def show
    @item = current_user.tackle_box_items.find(params[:id])

    @items =
      current_user.tackle_box_items.
        order(created_at: :asc).includes(:bait)

    @new_catch = current_user.fish_catches.new(bait: @item.bait)

    @fish_catches =
      current_user.fish_catches.
        where(bait: @item.bait).order(created_at: :desc)
  end

  def create
    @bait = Bait.find(params[:bait_id])
    @item = current_user.tackle_box_items.create!(bait: @bait)

    @bait.my_tackle_box_item = @item

    respond_to do |format|
      format.html { redirect_to baits_path }
      format.turbo_stream { render "tackle_box_items/change", format: "turbo_stream", locals: { bait: @bait } }
    end
  end

  def destroy
    @item = current_user.tackle_box_items.find(params[:id])
    @item.destroy

    @bait = @item.bait

    respond_to do |format|
      format.html { redirect_to baits_path }
      format.turbo_stream { render "tackle_box_items/change", format: "turbo_stream", locals: { bait: @bait } }
    end
  end
end
