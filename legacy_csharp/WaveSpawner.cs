using Godot;
using System;
using System.Collections.Generic;

public partial class WaveSpawner : Node
{
    [Signal] public delegate void WaveStartedEventHandler(int waveNumber);

    [Export] public float SpawnInterval { get; set; } = 30.0f;

    public event Action<Actor> UnitSpawned = delegate { };

    private readonly Dictionary<string, int> _upgradeLevels = new Dictionary<string, int>();
    private Node2D _actorParent;
    private PackedScene _laneUnitScene;
    private LaneManager _laneManager;
    private float _timer;
    private int _waveNumber;
    private bool _running;

    public override void _Process(double delta)
    {
        if (!_running || _actorParent == null || _laneUnitScene == null || _laneManager == null)
        {
            return;
        }

        _timer -= (float)delta;
        if (_timer <= 0.0f)
        {
            SpawnWave();
            _timer = SpawnInterval;
        }
    }

    public void Configure(Node2D actorParent, PackedScene laneUnitScene, LaneManager laneManager)
    {
        _actorParent = actorParent;
        _laneUnitScene = laneUnitScene;
        _laneManager = laneManager;
    }

    public void StartSpawning()
    {
        _running = true;
        _timer = SpawnInterval;
    }

    public void StopSpawning()
    {
        _running = false;
    }

    public void SetUnitUpgradeLevel(string unitId, int level)
    {
        _upgradeLevels[unitId] = level;
    }

    private void SpawnWave()
    {
        _waveNumber++;
        EmitSignal(SignalName.WaveStarted, _waveNumber);

        foreach (var lane in new[] { LaneId.Top, LaneId.Middle, LaneId.Bottom })
        {
            SpawnLanePair("line_melee", lane);
            SpawnLanePair("line_mage", lane);

            if (_waveNumber % 3 == 0)
            {
                SpawnLanePair("line_siege", lane);
            }
        }
    }

    private void SpawnLanePair(string unitId, LaneId lane)
    {
        SpawnUnit(unitId, TeamId.Player, lane);
        SpawnUnit(unitId, TeamId.Enemy, lane);
    }

    private void SpawnUnit(string unitId, TeamId team, LaneId lane)
    {
        var definitions = GameCatalog.CreateUnitDefinitions();
        if (!definitions.TryGetValue(unitId, out var definition))
        {
            return;
        }

        var unit = _laneUnitScene.Instantiate<LaneUnit>();
        _actorParent.AddChild(unit);

        var stats = CreateScaledStats(definition);
        unit.ConfigureLaneUnit(
            unitId,
            team,
            lane,
            _laneManager.GetSpawnPosition(team, lane),
            _laneManager.GetLaneTarget(team, lane),
            stats);

        UnitSpawned(unit);
    }

    private ActorStats CreateScaledStats(UnitDefinition definition)
    {
        var stats = definition.Stats.CloneStats();
        var level = _upgradeLevels.TryGetValue(definition.Id, out var storedLevel) ? storedLevel : 0;
        var multiplier = 1.0f + level * 0.15f;
        stats.MaxHealth *= multiplier;
        stats.AttackDamage *= multiplier;
        return stats;
    }
}
