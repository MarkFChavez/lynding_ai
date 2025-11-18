class ReferralAgentsController < ApplicationController
  before_action :set_referral_agent, only: %i[ show edit update destroy ]

  # GET /referral_agents or /referral_agents.json
  def index
    @referral_agents = ReferralAgent.order(created_at: :desc).page(params[:page]).per(5)
  end

  # GET /referral_agents/1 or /referral_agents/1.json
  def show
  end

  # GET /referral_agents/new
  def new
    @referral_agent = ReferralAgent.new
  end

  # GET /referral_agents/1/edit
  def edit
  end

  # POST /referral_agents or /referral_agents.json
  def create
    @referral_agent = ReferralAgent.new(referral_agent_params)
    @referral_agent.created_by = Current.user
    @referral_agent.updated_by = Current.user

    respond_to do |format|
      if @referral_agent.save
        format.html { redirect_to @referral_agent, notice: "Referral agent was successfully created." }
        format.json { render :show, status: :created, location: @referral_agent }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @referral_agent.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /referral_agents/1 or /referral_agents/1.json
  def update
    @referral_agent.updated_by = Current.user
    respond_to do |format|
      if @referral_agent.update(referral_agent_params)
        format.html { redirect_to @referral_agent, notice: "Referral agent was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @referral_agent }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @referral_agent.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /referral_agents/1 or /referral_agents/1.json
  def destroy
    loan_count = @referral_agent.loans.count
    @referral_agent.destroy!

    respond_to do |format|
      if loan_count > 0
        format.html { redirect_to referral_agents_path, notice: "Referral agent was successfully deleted. #{loan_count} loan(s) will no longer have an assigned agent.", status: :see_other }
        format.json { head :no_content }
      else
        format.html { redirect_to referral_agents_path, notice: "Referral agent was successfully deleted.", status: :see_other }
        format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_referral_agent
      @referral_agent = ReferralAgent.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def referral_agent_params
      params.expect(referral_agent: [ :name, :email, :phone, :commission_rate ])
    end
end
